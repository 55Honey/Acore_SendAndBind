--
-- Created by IntelliJ IDEA.
-- User: Silvia
-- Date: 21/05/2021
-- Time: 13:16
-- To change this template use File | Settings | File Templates.
-- Originally created by Honey for Azerothcore
-- requires ElunaLua module


--Items which are Bind on Equip by default will arrive soulbound in the mail
------------------------------------------------------------------------------------------------
-- ADMIN GUIDE:  -  compile the core with ElunaLua module
--               -  adjust config in this file
--               -  Change the '.send mail' in your webshop to '.senditemandbind'
--               -  add this script to ../lua_scripts/
------------------------------------------------------------------------------------------------

local Config = {}

Config.subject = "Shop Item"
Config.message = ""
Config.minGMRankForSend = 2

------------------------------------------
-- NO ADJUSTMENTS REQUIRED BELOW THIS LINE
------------------------------------------

local function log(line, logToConsole)
    local f = io.open(debug.getinfo(1).source:match("@?(.*/)") .. "/send-and-bind.log", "a")
    f:write(line)
    f:write("\n")
    f:close()

    if logToConsole == nil or logToConsole == true then
        print("[SendAndBind] " .. line)
    end
end

local function onError(err)
    log("Error: " .. err)
end

local function SendAndBind(event, player, command)
    local itemGUID
    local item_id
    local item_amount
    local targetGUID
    local SAB_eventId
    local mailText

    local commandArray = SAB_splitString(command)

    if commandArray[1] ~= "senditemandbind" then
        return
    end

    if commandArray[1] == "senditemandbind" then
        -- make sure the player is properly ranked
        if player ~= nil then
            if player:GetGMRank() < Config.minGMRankForSend then
                return
            end
        end

        if commandArray[2] == nil or commandArray[3] == nil then
            return "missing argument"
        end

        commandArray[2] = commandArray[2]:gsub("[';\\, ]", "")
        commandArray[3] = commandArray[3]:gsub("[';\\, ]", "")
        if commandArray[4] ~= nil then
            commandArray[4] = commandArray[4]:gsub("[';\\, ]", "")
        end

        targetGUID = commandArray[2]
        item_id = commandArray[3]

        if commandArray[4] == nil then
            item_amount = 1
        else
            item_amount = commandArray[4]
        end

        if commandArray[5] ~= nil then
            local counter
            for index,value in ipairs(commandArray) do
                if index >= 5 then
                    if mailText == nil then
                        mailText = commandArray[index].." "
                    else
                        mailText = mailText..commandArray[index].." "
                    end
                end
            end
        else
            mailText = ""
        end

        log("", false)
        log("[====" ..  os.date("%m-%d-%Y %I:%M %p") .. "====]")
        log("targetGUID = " .. tonumber(targetGUID))
        log("item_id = " .. tonumber(item_id))
        log("item_amount = " .. item_amount)

        local success
        success, itemGUID = xpcall(SendMail, onError, Config.subject, Config.message..mailText, targetGUID, 0, 61, 15, 0, 0, item_id, item_amount)
        if not success then
            return false
        end
        log("Sent mail, itemGUID = " .. tonumber(itemGUID))

        local player = GetPlayerByGUID(targetGUID)
        if player == nil then
            -- Player is offline
            log("Player with GUID " .. targetGUID .. " is offline.")

            local sql = 'UPDATE `item_instance` SET `flags` = `flags` | 1 WHERE `guid` = '..tonumber(itemGUID)..';'
            log(sql)
            CharDBExecute(sql)

            sql = 'UPDATE `item_instance` SET `owner_guid` = '..tonumber(targetGUID)..' WHERE `guid` = '..tonumber(itemGUID)..';'
            log(sql)
            CharDBExecute(sql)

            log("Executed UPDATE queries.")
        else
            -- Player is online
            log("Player " .. player:GetName() .. " is online.")
            local item = player:GetMailItem(itemGUID)
            if item == nil then
                onError("Player:GetMailItem returned nil item reference.")
                return false
            end

            item:SetOwner(player)
            item:SetBinding(true)
            log("Executed SetOwner and SetBinding.")
        end

        return false
    end
end


local PLAYER_EVENT_ON_COMMAND = 42            --(event, player, command)
RegisterPlayerEvent(PLAYER_EVENT_ON_COMMAND, SendAndBind)

function SAB_splitString(inputstr, seperator)
    if seperator == nil then
        seperator = "%s"
    end
    local t={}
    for str in string.gmatch(inputstr, "([^"..seperator.."]+)") do
        table.insert(t, str)
    end
    return t
end
