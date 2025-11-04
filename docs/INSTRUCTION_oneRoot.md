# 目的

**単一の Terraform root**（1 つの backend/state）で、複数アカウント × マルチリージョンの VPC 関連（VPC / Subnet / IGW / NAT / Route / NACL）を IaC 管理する。学習・小規模チームでの一括運用を想定。

---

## 方針の要点

- **root を 1 つ**に統合（例: `repo/stacks/global/`）
- **S3 + DynamoDB** を 1 つの backend に集約（`key = "network/global.tfstate"` など）
- **provider alias 必須**: アカウント × リージョンごとに `provider "aws" { alias = ... }` を静的に定義
- **スタック合成をモジュール化**: 既存の VPC/IGW/Subnet/NAT/Route/NACL 組み合わせを `modules/network_stack` に切り出し
- **root から組合せ分だけ module 呼び出し**し、`providers = { aws = aws.<alias> }` でバインド

> Terraform の仕様上、**プロバイダ選択を動的に切り替えることは不可**。alias を**列挙**して `providers` で**静的に割当**する。

---

## ディレクトリ構成

```
repo/
├─ modules/
│  ├─ vpc/
│  ├─ igw/
│  ├─ subnet/
│  ├─ nat/
│  ├─ route/
│  ├─ nacl/
│  └─ network_stack/   # ← 合成モジュール（単一 root 用）
└─ stacks/
   └─ global/          # ← Terraform root（単一 state）
      ├─ versions.tf
      ├─ backend.tf
      ├─ providers.tf  # alias を列挙
      ├─ main.tf       # 組合せ分の module 呼び出し
      └─ all.auto.tfvars
```

---

## 変数設計（例）

- `all.auto.tfvars` で、**組合せ（アカウント × リージョン）ごと**に VPC 集合を渡す。
- 例: `prod_core_apne1_vpcs`, `prod_core_apne3_vpcs` ...

```hcl
prod_core_apne1_vpcs = {
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
    nat  = { per_az = true }
    nacl = {}
  }
}
```

---

## `modules/network_stack` の役割

- 既存の VPC/IGW/Subnet/NAT/Route/NACL モジュールを**1 つの呼び出しで束ねる**。
- 引数: `env`, `account_alias`, `region`, `vpcs`（将来は厳密型へ）
- 呼び出し側（root）から **`providers = { aws = aws.<alias> }`** を渡す。

---

## backend / provider / module 呼び出し（抜粋）

**backend（単一）**

```hcl
terraform {
  backend "s3" {
    bucket         = "tfstate-global"         # 変更必須
    dynamodb_table = "tfstate-locks-global"   # 変更必須
    region         = "ap-northeast-1"
    key            = "network/global.tfstate"
    encrypt        = true
  }
}
```

**providers（alias 列挙）**

```hcl
provider "aws" {
  alias   = "prod_core_apne1"
  region  = "ap-northeast-1"
  profile = "prod-core"       # または assume_role
}

provider "aws" {
  alias   = "prod_core_apne3"
  region  = "ap-northeast-3"
  profile = "prod-core"
}
```

**root からの呼び出し**

```hcl
module "net_prod_core_apne1" {
  source        = "../../modules/network_stack"
  env           = "prod"
  account_alias = "core"
  region        = "ap-northeast-1"
  vpcs          = var.prod_core_apne1_vpcs
  providers     = { aws = aws.prod_core_apne1 }
}
```

---

## ルーティング実装の注意（AZ キー整合）

- NAT/サブネットのキーが `public-a` / `private-a` のように**AZ サフィックス**を持つ前提。
- `route` モジュール内で **AZ 文字を抽出**して整合を取る（例: 正規表現で末尾 `a|c|d` を抽出）。

---

## コマンド

```bash
terraform -chdir=repo/stacks/global init
terraform -chdir=repo/stacks/global validate
terraform -chdir=repo/stacks/global plan
terraform -chdir=repo/stacks/global apply -auto-approve
```

### 破棄

```bash
terraform -chdir=repo/stacks/global destroy -auto-approve
```

---

## 運用メモ

- **メリット**: 全差分を 1 回で把握／スタック間参照が容易
- **デメリット**: State ロックが広い、実行時間 ↑、blast radius↑（部分適用の常用は非推奨）
- **拡張**: アカウント／リージョン追加時は provider alias と module ブロックを追加

---

## 次のアクション

1. 単一 root 版スキャフォールドを使って backend 名・profile/assume_role を実環境に合わせる
2. `all.auto.tfvars` の VPC 定義を調整
3. `init → plan → apply` を実施し、AWS CLI で検証
