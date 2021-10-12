icacls U: /grant avdusers:(M)
icacls U: /grant "Creator Owner":(OI)(CI)(IO)(M)
icacls U: /remove "Authenticated Users"
icacls U: /remove "Builtin\Users"