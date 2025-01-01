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
add_new_item.sh -i item_name -v vault_name
```

Encrypt a item:
```bash
encrypt_item.sh -i item_name -v vault_name
```

Decrypt a item:
```bash
decrypt_item.sh -i item_name -v vault_name
```

List all vaults in the keyring directory:
```bash
list_vaults.sh
```

Generate password:
```bash
generate_password.sh length
```
