```
На SRV-HQ
echo "P@ssw0rd" | kinit admin@AU.TEAM
ipa role-add "CIFS server" --desc="Role for CIFS server"
ipa role-add "Organization units" --desc="Role for Organization units"

На АДМ (Веб-мордв Freeipa)
В созданные группы добавляешь всё

Веб-морда айдеко
