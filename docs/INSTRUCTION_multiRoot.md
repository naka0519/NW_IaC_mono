# 目的

複数 AWS アカウントかつマルチリージョン（例: ap-northeast-1, ap-northeast-3）で、1 アカウント内に複数の VPC が存在し得る前提の VPC 関連（VPC / Subnet / Route / NAT / IGW / NACL）を **Terraform モジュール**で IaC 管理する。

---

## 要件整理

- **R1**: 1 アカウント内に複数 VPC を定義できること
- **R2**: マルチリージョン（ap-northeast-1, ap-northeast-3 等）に対応
- **R3**: 複数アカウントを **1 つのモノレポ**に収容（ステートと認証は分離）
- **R4**: 学習用途のため、小さな変更単位で「作る → 検証」を繰り返せること
- **R5**: 命名規則・タグ・バージョン・ステートなどベース運用を明確化

---

## 全体方針

### 命名規則

`<env>-<account_alias>-<region>-<component>[-<suffix>]`
例: `prod-core-apne1-vpc-main`

### 共通タグ

`Project, Env, Owner, CostCenter, ManagedBy=Terraform` を全リソースへ付与

### ステート管理

- **推奨**: S3 backend + DynamoDB lock。アカウントごとに別バケット・テーブル
- キーは `network/<region>/stack.tfstate` のようにリージョン単位で分離

### Provider 戦略

- **アカウント切替**: `profile` または `assume_role`
- **リージョン切替**: スタック（ディレクトリ）をリージョン単位に分離（1 stack = 1 region）

### 入力モデリング（tfvars）

- 1 スタックに `env, account_alias, region, vpcs` を与える
- `vpcs` は VPC 名 → 属性（CIDR、サブネット集合、NAT 戦略、NACL 設定等）のマップ

### モジュール分割

- `vpc`, `igw`, `subnet`, `nat`, `route`, `nacl` を最小分割
- 将来は `vpce`, `sg`, `tgw`, `peering` などへ拡張

---

## モノレポ構成（初期案）

```
repo/
├─ modules/
│  ├─ vpc/      # VPC 基本属性
│  ├─ igw/      # インターネットゲートウェイ
│  ├─ subnet/   # public/private サブネット
│  ├─ nat/      # per-AZ NAT / EIP
│  ├─ route/    # RT: public(IGW)/private(NAT)
│  └─ nacl/     # NACL（public/private 各1枚+紐付け）
├─ stacks/
│  ├─ prod/
│  │  └─ core/
│  │     ├─ ap-northeast-1/
│  │     │  ├─ main.tf / providers.tf / versions.tf / backend.tf
│  │     │  └─ vpcs.auto.tfvars  # ← VPC集合を宣言
│  │     └─ ap-northeast-3/
│  │        └─ ...
│  └─ dev/
│     └─ core/
│        └─ ap-northeast-1/
└─ policies/, .tooling/ （任意）
```

---

## tfvars（入力スキーマ例）

```hcl
env            = "prod"
account_alias  = "core"
region         = "ap-northeast-1"

vpcs = {
  main = {
    cidr = "10.10.0.0/16"
    tags = { Tier = "primary" }

    public_subnets = {
      "public-a" = { cidr = "10.10.0.0/20",  az = "ap-northeast-1a", map_public_ip_on_launch = true }
      "public-c" = { cidr = "10.10.16.0/20", az = "ap-northeast-1c", map_public_ip_on_launch = true }
    }
    private_subnets = {
      "private-a" = { cidr = "10.10.32.0/19", az = "ap-northeast-1a" }
      "private-c" = { cidr = "10.10.64.0/19", az = "ap-northeast-1c" }
    }

    nat = { per_az = true }

    nacl = {
      public = {
        ingress = [
          { rule_no = 100, protocol = "6",  action = "allow", cidr = "0.0.0.0/0", from = 80,   to = 80 },
          { rule_no = 110, protocol = "6",  action = "allow", cidr = "0.0.0.0/0", from = 443,  to = 443 },
          { rule_no = 200, protocol = "6",  action = "allow", cidr = "0.0.0.0/0", from = 1024, to = 65535 }
        ]
        egress = [ { rule_no = 100, protocol = "-1", action = "allow", cidr = "0.0.0.0/0", from = 0, to = 0 } ]
      }
      private = {
        ingress = [ { rule_no = 100, protocol = "-1", action = "allow", cidr = "10.10.0.0/16", from = 0, to = 0 } ]
        egress  = [ { rule_no = 100, protocol = "-1", action = "allow", cidr = "0.0.0.0/0",   from = 0, to = 0 } ]
      }
    }
  }
}
```

---

## 実装ステップ（検証コマンド付き）

> 各ステップは小さく適用して **aws CLI で検証**。NAT はコストに注意。

### 0. ブートストラップ（アカウントごとに 1 回）

- S3 バケット（例: `tfstate-prod-core`）と DynamoDB テーブル（例: `tfstate-locks-prod-core`）を作成
- 検証

  ```bash
  aws s3 ls s3://tfstate-prod-core
  aws dynamodb describe-table --table-name tfstate-locks-prod-core
  ```

### 1. VPC のみ作成（最小）

```bash
cd stacks/prod/core/ap-northeast-1
terraform init && terraform validate
terraform plan  -var-file="vpcs.auto.tfvars"
terraform apply -auto-approve -var-file="vpcs.auto.tfvars"
aws ec2 describe-vpcs --filters "Name=tag:Name,Values=prod-core-ap-northeast-1-vpc-main"
```

### 2. サブネット追加

```bash
terraform apply -auto-approve -var-file="vpcs.auto.tfvars"
aws ec2 describe-subnets --filters "Name=vpc-id,Values=<VPC_ID>"
```

### 3. IGW + Public ルート

```bash
terraform apply -auto-approve -var-file="vpcs.auto.tfvars"
aws ec2 describe-route-tables --filters "Name=vpc-id,Values=<VPC_ID>"
```

### 4. NAT + Private ルート

```bash
terraform apply -auto-approve -var-file="vpcs.auto.tfvars"
aws ec2 describe-nat-gateways --filter "Name=vpc-id,Values=<VPC_ID>"
```

### 5. NACL

```bash
terraform apply -auto-approve -var-file="vpcs.auto.tfvars"
aws ec2 describe-network-acls --filters "Name=vpc-id,Values=<VPC_ID>"
```

### 6. 同一アカウントに VPC を追加

- `vpcs.auto.tfvars` の `vpcs` に新しいキー（例: `analytics`）を追加
- Plan で差分確認 →Apply

### 7. マルチリージョン化

- `stacks/prod/core/ap-northeast-3/` を 1 の構成からコピー
- `backend.tf` の `region`/`key` と `vpcs.auto.tfvars` の `region` を `ap-northeast-3` へ変更

### 8. 複数アカウントをモノレポ化

- `stacks/prod/<another-account>/<region>/` を追加
- `providers.tf` の `profile` / `assume_role`、`backend.tf` のバケット/テーブル/キーをアカウント別に

---

## 運用ベストプラクティス

- **入力の型厳密化**（学習後に any → object へ）
- **CI で lint/format**（tflint, terraform fmt/validate, checkov）
- **ブレークダウン**: VPC エンドポイント・SG・TGW は別スタックで疎結合
- **コスト管理**: NAT per-AZ は必要時のみ。学習中は無効化可

---

## ロールバックと破棄

- 失敗時の最小単位はスタック（リージョン）
- `terraform destroy -var-file="vpcs.auto.tfvars"`（NAT/IGW 依存関係に注意）

---

## 次のアクション

1. 下記のスキャフォールドを展開（README, モジュール, スタック雛形）
2. `backend.tf` の S3/DynamoDB 名を実環境に合わせて修正
3. `providers.tf` の `profile` または `assume_role` を設定
4. ステップ 1 の VPC 最小構成から適用 → 検証

---

## 付録: コマンド・スニペット

```bash
# 初回
terraform -chdir=stacks/prod/core/ap-northeast-1 init
terraform -chdir=stacks/prod/core/ap-northeast-1 plan  -var-file=vpcs.auto.tfvars
terraform -chdir=stacks/prod/core/ap-northeast-1 apply -var-file=vpcs.auto.tfvars -auto-approve

# 破棄（学習リソース）
terraform -chdir=stacks/prod/core/ap-northeast-1 destroy -var-file=vpcs.auto.tfvars -auto-approve
```
