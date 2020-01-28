data "vault_identity_group" "use_group" {
  for_each   = toset(var.groups)
  group_name = each.value
}

resource "vault_identity_group_policies" "use_group" {
  for_each  = toset(var.groups)
  group_id  = data.vault_identity_group.use_group[each.value].group_id
  policies  = var.policies
  exclusive = false
}
