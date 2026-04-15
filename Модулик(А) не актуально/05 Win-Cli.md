1. Заходим admin, ставим RSAT
```
WindowsCapability -Name RSAT* -Online | Select-Object -Property DisplayName, State
