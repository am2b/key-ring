Create directory of keyring and create config file:
```bash
keyring_init.sh
```

Create a new vault in keyring directory:
```bash
create_new_vault.sh new_vault_name
```

Add a new item to a vault:
```bash
add_new_item.sh -v vault_name -i item_name
```

View a item:
```bash
view_item.sh -v vault_name -i item_name
```

Fuzzy view a item:
```bash
fuzzy_view_item.sh
```

Edit a item:
```bash
edit_item.sh -v vault_name -i item_name
```

Fuzzy edit a item:
```bash
fuzzy_edit_item.sh
```

Archive an item:
```bash
archive_item.sh -v vault_name -i item_name
```

List all vaults in the keyring directory:
```bash
list_vaults.sh
```

Generate password:
```bash
generate_password.sh length
```
