if ( CLIENT ) then
    
    local file = file
    local util = util
    local MsgC = MsgC
    local Color = Color
    local pairs = pairs
    local table = table
    local timer = timer
    local ipairs = ipairs
    local player = player
    local IsValid = IsValid
    local PrintTable = PrintTable
    
    --[[--------------------------------------------------------------------------
    -- Utility Functions
    --------------------------------------------------------------------------]]--
    
    local NO_NAME_MATCHES    = "No players were found with the name '%s'"
    local TOO_MANY_MATCHES   = "Multiple players were found with the name '%s'"
    local NO_STEAMID_MATCHES = "No players were found with the steamid '%s'"
    
    local function GetPlayerByName( name )
        if ( name:Trim() == "" ) then return nil, NO_NAME_MATCHES:format( name ) end
        local found = 0
        local foundPly
        
        for _, ply in ipairs( player.GetAll() ) do
            local plyName = ply:Nick():lower()
            if ( plyName == name ) then return ply end
            if ( plyName:find( name, 1, true ) ) then
                found = found + 1
                foundPly = ply
            end
        end
        
        if ( found == 1 ) then return foundPly end
        if ( found == 0 ) then return nil, NO_NAME_MATCHES:format( name ) end
        return nil, TOO_MANY_MATCHES:format( name )
    end
    
    local function GetPlayerBySteamID( sid )
        sid = sid:upper()
        for _, ply in ipairs( player.GetAll() ) do
            if ( ply:SteamID() == sid ) then return ply end
        end
        
        return nil, NO_STEAMID_MATCHES:format( sid )
    end
    
    -- Try to find a valid player via name or SteamID
    local function GetConnectedPlayer( arg )
        arg = arg:lower()
        if ( arg:sub(1,8):find( "steam_0:", 1, true ) or arg == "bot" ) then
            return GetPlayerBySteamID( arg )
        else
            return GetPlayerByName( arg )
        end
    end
    
    --[[--------------------------------------------------------------------------
    -- PAC Blacklist Functions
    --------------------------------------------------------------------------]]--
    
    pac_blacklist = pac_blacklist or {}
    
    local debug = CreateClientConVar( "pac_blacklist_debug", 1, true, false )
    
    local function showError( err )
        MsgC( Color(255,100,100), "[ERROR] pac_blacklist: " .. err .. "\n" )
    end
    
    local function showInfo( str )
        if ( debug:GetBool() ) then MsgC( Color(100,255,100), "[INFO] pac_blacklist: "  .. str .. "\n" ) end
    end
    
    --[[
        Writes the current blacklisted players out to the blacklist file in a JSON-encoded string
    --]]
    local function writeToFile()
        file.Write( "pac_blacklist.txt", util.TableToJSON( pac_blacklist, true ) )
    end
    
    --[[
        Reads the JSON data from the blacklist file and returns a table.
        If the file doesn't exist, is empty, or formatted improperly, an empty
        table will be returned instead.
    --]]
    local function readFromFile()
        if ( not file.Exists( "pac_blacklist.txt", "DATA" ) ) then return "[]" end
        
        local json = file.Read( "pac_blacklist.txt", "DATA" )
        if ( json:Trim() == "" ) then
            return {}
        else
            return util.JSONToTable( json ) or {}
        end
    end
    
    local function setPACVisible( ply, bool )
        pac.TogglePartDrawing( ply, bool )
    end
    
    --[[
        Adds the player or their SteamID to the blacklist. If given a valid player,
        their PAC visibility will be disabled.
    --]]
    local function addToBlacklist( id, name )
            local ply = id
            id   = ply:SteamID()
            name = ply:Nick()
            setPACVisible( ply, false )
        end
        
        pac_blacklist[id] = name
    end
    
    --[[
        Removes the player or their SteamID from the blacklist. If given a valid player,
        their PAC visibility will be enabled.
    --]]
    local function removeFromBlacklist( id )
            local ply = id
            setPACVisible( ply, true )
            id = ply:SteamID()
        end
        
        pac_blacklist[id] = nil
    end
    
    --[[--------------------------------------------------------------------------
    -- PAC Blacklist Console Commands
    --------------------------------------------------------------------------]]--
    
    concommand.Add( "pac_blacklist", function()
        showInfo( ("Blacklist contains %d players"):format( table.Count(pac_blacklist) ) )
        PrintTable( pac_blacklist )
    end )
    
    -- Add the user (by name or SteamID) to the blacklist and write the changes to disk
    concommand.Add( "pac_blacklist_add", function( ply, cmd, args, str )
        local target, err = GetConnectedPlayer( str )
        if ( not target and err ) then showError( err ) return end
        
        showInfo( ("Blocking PACs from %s (%s)"):format( target:Nick(), target:SteamID() ) )
        
        addToBlacklist( target )
        writeToFile()
    end )
    
    -- Remove the user (by name or SteamID) from the blacklist and write the changes to disk
    concommand.Add( "pac_blacklist_remove", function( ply, cmd, args, str )
        local target, err = GetConnectedPlayer( str )
        if ( not target and err ) then showError( err ) return end
        
        showInfo( ("Unblocking PACs from %s (%s)"):format( target:Nick(), target:SteamID() ) )
        
        removeFromBlacklist( target )
        writeToFile( pac_blacklist )
    end )
    
    -- Remove all users from the blacklist and write the changes to disk
    concommand.Add( "pac_blacklist_clear", function( ply, cmd, args, str )
        showInfo( ("Removing all blacklisted players (total: %d)"):format( table.Count(pac_blacklist) ) )
        
        for id, _ in pairs( pac_blacklist ) do
            removeFromBlacklist( player.GetBySteamID( id ) or id )
        end
        pac_blacklist = {}
        writeToFile()
    end )
    
    --[[--------------------------------------------------------------------------
    -- PAC Blacklist Hooks
    --------------------------------------------------------------------------]]--
    
    -- Load the PAC blacklist from disk once the client has fully loaded
    hook.Add( "InitPostEntity", "pac_blacklist_init", function()
        showInfo( "Loading PAC blacklist..." )
        local data = readFromFile()
        
        for id, name in pairs( data ) do
            addToBlacklist( id, name )
        end
    end )
    
    -- Listen for when other players initialize on the server and check if they are on the blacklist
    hook.Add( "NetworkEntityCreated", "pac_blacklist_block", function( ent )
        -- Client isn't fully valid until the next frame
        timer.Simple( 0, function()
            if ( not IsValid( ent ) or not ent:IsPlayer() ) then return end
            
            if ( pac_blacklist[ent:SteamID()] ) then
                showInfo( ("%s (%s) is on blacklist -- blocking their PACs"):format( ent:Nick(), ent:SteamID() ) )
                setPACVisible( ent, false )
            end
        end )
    end )
    
end