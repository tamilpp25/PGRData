local XFubenActivityAgency = require("XModule/XBase/XFubenActivityAgency")
local XDlcRoom = require("XModule/XDlcRoom/XEntity/XDlcRoom")
local XDlcWorldFight = require("XModule/XDlcRoom/XDlcWorldFight/XDlcWorldFight")

---@class XDlcActivityAgency : XFubenActivityAgency
local XDlcActivityAgency = XClass(XFubenActivityAgency, "XDlcActivityAgency")

function XDlcActivityAgency:DlcCheckClickHrefCanEnter(roomId, nodeId, worldId, createTime)
    if not self:DlcCheckActivityInTime() then
        XUiManager.TipText("CommonActivityEnd")
        return false
    end

    if XTime.GetServerNowTimestamp() > createTime + XMVCA.XDlcRoom:GetInviteChatCacheTime() then
        XUiManager.TipText("RoomHrefDisabled")
        return false
    end

    return true
end

function XDlcActivityAgency:DlcGetRoomProxy()
    return XDlcRoom.New()
end

function XDlcActivityAgency:DlcGetFightEvent()
    return XDlcWorldFight.New()
end

function XDlcActivityAgency:DlcReconnect()
    XMVCA.XDlcRoom:ReconnectToWorld()
end

function XDlcActivityAgency:DlcActivityTimeOutRunMain()
    XLuaUiManager.RunMain(true)
    XUiManager.TipText("CommonActivityEnd")
end

function XDlcActivityAgency:DlcGetPlayerCustomData()
    return nil
end

function XDlcActivityAgency:DlcInitFight()
    XMVCA.XDlcRoom:InitFight()
end

function XDlcActivityAgency:DlcCheckActivityInTime()
    return false
end

function XDlcActivityAgency:DlcRegisterActivity()
    self:RegisterActivityAgency()
    XMVCA.XDlcWorld:RegisterActivity(self:DlcGetWorldType(), self:GetId())
end

function XDlcActivityAgency:DlcGetWorldType()
    return nil
end

function XDlcActivityAgency:DlcGetNonnegativeAttribs()
    return {
        [XDlcNpcAttribType.Life] = true,
        [XDlcNpcAttribType.CharacterValue] = true,
        [XDlcNpcAttribType.ExSkillPoint] = true,
        [XDlcNpcAttribType.IdleSpinningSpeed] = true,
        [XDlcNpcAttribType.RunSpinningSpeed] = true,
        [XDlcNpcAttribType.CustomEnergyGroup1] = true,
        [XDlcNpcAttribType.CustomEnergyGroup2] = true,
        [XDlcNpcAttribType.CustomEnergyGroup3] = true,
        [XDlcNpcAttribType.CustomEnergyGroup4] = true,
        [XDlcNpcAttribType.Speed] = true,
        [XDlcNpcAttribType.JumpSpeed] = true,
        [XDlcNpcAttribType.RunSpeed] = true,
        [XDlcNpcAttribType.RunSpeedCOE] = true,
        [XDlcNpcAttribType.JumpSpeedCOE] = true,
        [XDlcNpcAttribType.IdleJumpSpeedCOE] = true,
        [XDlcNpcAttribType.WalkJumpSpeedCOE] = true,
        [XDlcNpcAttribType.SprintJumpSpeedCOE] = true,
        [XDlcNpcAttribType.RunStartJumpSpeedCOE] = true,
        [XDlcNpcAttribType.SprintStartJumpSpeedCOE] = true,
        [XDlcNpcAttribType.RotationSpeed] = true,
    }
end

function XDlcActivityAgency:DlcGetEnlargedAttribs()
    return {
        [XDlcNpcAttribType.Speed] = true,
        [XDlcNpcAttribType.JumpSpeed] = true,
        [XDlcNpcAttribType.RunSpeed] = true,
        [XDlcNpcAttribType.RunSpeedCOE] = true,
        [XDlcNpcAttribType.JumpSpeedCOE] = true,
        [XDlcNpcAttribType.IdleJumpSpeedCOE] = true,
        [XDlcNpcAttribType.WalkJumpSpeedCOE] = true,
        [XDlcNpcAttribType.SprintJumpSpeedCOE] = true,
        [XDlcNpcAttribType.RunStartJumpSpeedCOE] = true,
        [XDlcNpcAttribType.SprintStartJumpSpeedCOE] = true,
        [XDlcNpcAttribType.RotationSpeed] = true,
    }
end

function XDlcActivityAgency:DlcGetWorldNpcBornMagicLevelMap(worldNpcData)
    return {}
end

function XDlcActivityAgency:DlcGetNpcAttrib(worldNpcData)
    local npcId = worldNpcData.Id
    local attribId = self:DlcGetAttribIdByNpcId(npcId)
    local attribConfig = XMVCA.XDlcWorld:GetAttributeConfigById(attribId)

    return self:DlcParseToXAttribs(attribConfig)
end

function XDlcActivityAgency:DlcGetBaseAttrib(npcId)
    local template = CS.StatusSyncFight.XNpcConfig.GetTemplate(npcId)

    if not template then
        return {}
    end

    local attribId = template.AttribId
    local attribConfig = XMVCA.XDlcWorld:GetAttributeConfigById(attribId)

    return self:DlcParseToXAttribs(attribConfig)
end

function XDlcActivityAgency:DlcGetAttribIdByNpcId(npcId)
    local template = CS.StatusSyncFight.XNpcConfig.GetTemplate(npcId)

    if not template then
        return {}
    end

    return template.AttribId
end

function XDlcActivityAgency:DlcParseToXAttribs(attribConfig)
    local result = {}
    local nonnegativeAttribs = self:DlcGetNonnegativeAttribs() or {}
    local enlargedAttribs = self:DlcGetEnlargedAttribs() or {}

    for attribStr, attribId in pairs(XDlcNpcAttribType) do
        result[attribId + 1] = 0
    end
    for attrStr, attrValue in pairs(attribConfig) do
        local attribId = XDlcNpcAttribType[attrStr]

        if attribId then
            if enlargedAttribs[attribId] then
                result[attribId + 1] = attrValue * 1000
            else
                result[attribId + 1] = attrValue
            end
        end
    end
    for attribId, attrValue in pairs(result) do
        local allowNegative = not (nonnegativeAttribs[attribId] or false)

        -- 必须取整，因为XAttrib.Value为int
        attrValue = math.floor(attrValue + 0.5)
        result[attribId] = CS.StatusSyncFight.XAttrib.Ctor(attrValue, allowNegative)
    end

    --- 特殊处理 先保留例子
    -- xAttribs[RunSpeedIndex]:SetBase(FixToInt(attribs[RunSpeedIndex] * fix.thousand / FPS_FIX))

    return result
end

function XDlcActivityAgency:DlcOpenInviteUi(inviteData)
    XLuaUiManager.Open("UiDlcMultiPlayerInvitationPopup", inviteData)
end

function XDlcActivityAgency:DlcCheckInviteUiShow()
    return XLuaUiManager.IsUiShow("UiDlcMultiPlayerInvitationPopup")
end

return XDlcActivityAgency
