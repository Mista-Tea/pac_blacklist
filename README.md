# pac_blacklist
Clientside ability to block other users' PACs rather than having to disable PAC entirely.

The blacklist is saved as `pac_blacklist.txt` inside the /data folder and is JSON encoded.
This allows the blacklist to persist across sessions and be automatically loaded upon server join.

## Console Commands

### `pac_blacklist`
Lists the SteamIDs and names of any players you currently have blacklisted.


### `pac_blacklist_add <Name/SteamID>`
Adds the given player to the blacklist. You can either type their partial name or put their SteamID.


### `pac_blacklist_remove <Name/SteamID>`
Removes the given player from the blacklist. You can either type their partial name or put their SteamID.


### `pac_blacklist_clear`
Removes all players from the blacklist.
