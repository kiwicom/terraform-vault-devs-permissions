# terraform-vault-devs-permissions

Terraform module for assigning policies to devs groups 

This module is an alternative to namespace policies, but instead of for an app running in `k8s` this is meant for devs.
When creating this resource you can take namespace policies (or policies from multiple namespaces) and adjust them.

### Permissions changes

Application `granny` running in production: 
```hcl
module "ns_granny_prod" {
  source  = "kiwicom/devs-permissions/vault"
  version = "1.0.0"  
  ...
  
  additional_policies = [
    module.my_database.roles_policies["rw"],
    "kw/infra/platform/temporary/istio-test-jerry/th-jerry/creds/tom_ro",
    "kw/secret/automation/granny/runtime",
    "kw/secret/platform/security/iam/production/creds/automation_granny",
    "kw/shared/automation/i-dont-know",
    "kw/3rd-party/datadog/creds/k8s-gcp-projects",
    "kw/3rd-party/logzio/creds/autobooking",
    "kw/3rd-party/some-company",
  ]
}
```

Granny devs
```hcl
module "automation_granny_devs" {
  source  = "kiwicom/devs-permissions/vault"
  version = "1.0.0"  
 
  groups = [
    "engineering.automation"
  ]

  policies = [
    "kw/infra/platform/temporary/our-sandbox-project/my-database/creds/rw",
    "kw/infra/platform/temporary/istio-test-tom/my-database/creds/ro",
    "kw/infra/platform/temporary/istio-test-jerry/their-database/creds/granny_ro",
    "kw/secret/automation/granny/runtime",
    "kw/secret/platform/security/iam/production/creds/sandbox_automation_granny",
    # maybe "kw/secret/platform/security/iam/sandbox/creds/automation_granny",
    "kw/shared/automation/i-dont-know",
    # "kw/3rd-party/datadog/creds/k8s-gcp-projects",
    "kw/3rd-party/logzio/creds/autobooking-sandbox",
    "kw/3rd-party/some-company",
  ]
}
```

- do not left production ReadWrite DB policies to devs. If they need access a DB give them sandbox, or change at least 
 permissions to ReadOnly `module.th_tom_db.roles_policies["rw"]` => `kw/infra/platform/temporary/istio-test-tom/my-database/creds/ro`,
 access to sandbox DB `kw/infra/platform/temporary/our-sandbox-project/my-database/creds/rw`
- it might be also good idea to change accesses to other apps to different role or to their sandboxes 
 `kw/secret/platform/security/iam/production/creds/automation_granny` => `kw/secret/platform/security/iam/production/creds/automation_granny_sandbox` 
 or `kw/secret/platform/security/iam/sandbox/creds/automation_granny`
- you definitely do not want tha app on developer's computer to change production secrets provided to others. 
 So removed `kw/secret/platform/security/iam/production/creds-maintainer` for development of the features of the 
 secrets manipulation use for example `kw/secret/platform/security/iam/sandbox/creds-maintainer`
- it is definitely preferred to assign policies to groups on one place - here, not as `runtime_use_groups` and 
 `use_groups` where the policies are created
- Issue: one group might get same policy from multiple modules. Then if the group is removed from one module the 
 policy will be removed no matter that it is still in place in different modul. With next apply the policy will be 
 reassigned, but it may cause some troubles and confusion

### Team's wildcard policies

Usually team develops multiple projects in same gitlab group if you do not want to name all projects like 

```hcl
  ...
  policies = [
    "kw/secret/automation/granny/runtime",
    "kw/secret/automation/app1/runtime",
    "kw/secret/automation/app2/runtime",
    "kw/secret/automation/app3/runtime",
    ...
  ]
  ...
```

you can manually create `kw/secret/automation/_wildcard_/runtime` and assign it instead

```hcl
resource "vault_policy" "automation_wildcard_runtime" {
  name   = "kw/secret/automation/_wildcard_/runtime"
  policy = <<EOT
path "kw/secret/automation/+/runtime/*" {
  capabilities = ["read", "list"]
}
path "kw/secret/data/automation/+/runtime/*" {
  capabilities = ["read",]
}
path "kw/secret/metadata/automation/+/runtime/*" {
  capabilities = ["read", "list"]
}
EOT
}
```
