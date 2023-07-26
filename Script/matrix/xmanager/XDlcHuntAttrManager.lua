local XUiDlcHuntUtil = require("XUi/XUiDlcHunt/XUiDlcHuntUtil")
local XDlcHuntChip = require("XEntity/XDlcHunt/XDlcHuntChip")

XDlcHuntAttrManagerCreator = function()
    local XDlcHuntAttrManager = {}

    local pairs = pairs
    local XDlcNpcAttribType = XDlcNpcAttribType
    local XAttrib = CS.StatusSyncFight.XAttrib
    -- 特定属性 非负
    local AttrNonnegative = {
        [XDlcNpcAttribType.Life] = true,
        [XDlcNpcAttribType.CharacterValue] = true,
        [XDlcNpcAttribType.ExSkillPoint] = true,
        [XDlcNpcAttribType.IdleSpinningSpeed] = true,
        [XDlcNpcAttribType.RunSpinningSpeed] = true,
        [XDlcNpcAttribType.CustomEnergyGroup1] = true,
        [XDlcNpcAttribType.CustomEnergyGroup2] = true,
        [XDlcNpcAttribType.CustomEnergyGroup3] = true,
        [XDlcNpcAttribType.CustomEnergyGroup4] = true,
    }

    local function Fix2XAttrib(attrTable)
        local result = {}
        for attrStr, attrId in pairs(XDlcNpcAttribType) do
            result[attrId + 1] = 0
        end
        for attrStr, attrValue in pairs(attrTable) do
            local attrId = XDlcNpcAttribType[attrStr]
            if attrId then
                result[attrId + 1] = attrValue
            end
        end
        for attrId, attrValue in pairs(result) do
            local allowNegative = true
            if AttrNonnegative[attrId] then
                allowNegative = false
            end
            -- 必须取整，因为XAttrib.Value为int
            attrValue = math.floor(attrValue + 0.5)
            result[attrId] = XAttrib.Ctor(attrValue, allowNegative)
        end

        --- 特殊处理 先保留例子
        --xAttribs[RunSpeedIndex]:SetBase(FixToInt(attribs[RunSpeedIndex] * fix.thousand / FPS_FIX))

        return result
    end

    local function GetNpcBaseAttrib(npcTemplateId)
        local template = CS.StatusSyncFight.XNpcConfig.GetTemplate(npcTemplateId)
        if not template then
            return {}
        end
        local attrId = template.AttribId
        local attrTable = XDlcHuntAttrConfigs.GetAttrTable(attrId)
        return Fix2XAttrib(attrTable)
    end

    local function GetNpcAttrib(worldNpcData)
        local npcId = worldNpcData.Id
        local character = XDataCenter.DlcHuntCharacterManager.GetCharacterByNpcId(npcId)
        local attrTable
        if not character then
            attrTable = {}
        else
            attrTable = character:GetBaseAttrTable()
        end

        for i, chipData in pairs(worldNpcData.Chips) do
            ---@type XDlcHuntChip
            local chip = XDlcHuntChip.New()
            chip:SetData(chipData)
            if not chip:IsEmpty() then
                local attrTableAssistant = chip:GetAttrTable()
                attrTable = XUiDlcHuntUtil.GetSumAttrTable(attrTable, attrTableAssistant)
            end
        end

        return Fix2XAttrib(attrTable)
    end

    local function GetWorldNpcBornMagicLevelMap(worldNpcData)
        local magicDict = {}
        for i, chipData in pairs(worldNpcData.Chips) do
            ---@type XDlcHuntChip
            local chip = XDlcHuntChip.New()
            chip:SetData(chipData)
            if not chip:IsEmpty() then
                local magicList = chip:GetMagicEventIds()
                --local magicLevel = chip:GetMagicLevel()
                for j = 1, #magicList do
                    local magicId = magicList[j]
                    magicDict[magicId] = (magicDict[magicId] or 0) + 1
                end
            end
        end
        return magicDict
    end

    function XDlcHuntAttrManager.Init()
        CS.StatusSyncFight.XFightDelegate.GetDlcBaseAttrib = GetNpcBaseAttrib
        CS.StatusSyncFight.XFightDelegate.GetDlcNpcAttrib = GetNpcAttrib
        CS.StatusSyncFight.XFightDelegate.GetWorldNpcBornMagicLevelMap = GetWorldNpcBornMagicLevelMap
    end

    XDlcHuntAttrManager.Init()
    return XDlcHuntAttrManager
end