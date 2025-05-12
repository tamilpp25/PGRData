local XBigWorldCommanderDIYConfigModel = require("XModule/XBigWorldCommanderDIY/XBigWorldCommanderDIYConfigModel")

---@class XBigWorldCommanderDIYModel : XBigWorldCommanderDIYConfigModel
local XBigWorldCommanderDIYModel = XClass(XBigWorldCommanderDIYConfigModel, "XBigWorldCommanderDIYModel")

function XBigWorldCommanderDIYModel:OnInit()
    -- 初始化内部变量
    -- 这里只定义一些基础数据, 请不要一股脑把所有表格在这里进行解析
    self:_InitTableKey()
    self._UsePartMap = {}
    self._PartColorMap = {}
    self._Gender = XEnumConst.PlayerFashion.Gender.Male
end

function XBigWorldCommanderDIYModel:ClearPrivate()
    -- 这里执行内部数据清理
    -- XLog.Error("请对内部数据进行清理")
end

function XBigWorldCommanderDIYModel:ResetAll()
    -- 这里执行重登数据清理
    -- XLog.Error("重登数据清理")
end

function XBigWorldCommanderDIYModel:GetCurrentCharacterId()
    local gender = self:GetValidGender()

    if gender == XEnumConst.PlayerFashion.Gender.Female then
        return XMVCA.XBigWorldGamePlay:GetCurrentAgency():GetInt("PlayerFemaleCharacterId")
    else
        return XMVCA.XBigWorldGamePlay:GetCurrentAgency():GetInt("PlayerMaleCharacterId")
    end
end

function XBigWorldCommanderDIYModel:GetCurrentNpcId()
    local characterId = self:GetCurrentCharacterId()

    return XMVCA.XBigWorldCharacter:GetCharacterNpcId(characterId)
end

function XBigWorldCommanderDIYModel:SetGender(value)
    self._Gender = value
end

function XBigWorldCommanderDIYModel:GetGender()
    return self._Gender
end

function XBigWorldCommanderDIYModel:SetUsePart(typeId, partId)
    self._UsePartMap[typeId] = partId
end

function XBigWorldCommanderDIYModel:GetUsePart(typeId)
    if XTool.IsNumberValid(self._UsePartMap[typeId]) then
        return self._UsePartMap[typeId]
    end

    return self:GetDlcPlayerFashionTypeDefaultPartIdByTypeId(typeId)
end

function XBigWorldCommanderDIYModel:SetUsePartColor(partId, colorId)
    self._PartColorMap[partId] = colorId
end

function XBigWorldCommanderDIYModel:GetUsePartColor(partId, gender)
    if XTool.IsNumberValid(self._PartColorMap[partId]) then
        if self:CheckAllowSelectColor(partId, gender) then
            return self._PartColorMap[partId]
        end
    end

    gender = self:GetValidGender(gender)

    local resIds = self:GetDlcPlayerFashionPartResIdById(partId)
    local resId = resIds[gender]

    return self:GetDlcPlayerFashionResDefaultColorIdById(resId) or 0
end

function XBigWorldCommanderDIYModel:GetUsePartMap()
    return self._UsePartMap
end

function XBigWorldCommanderDIYModel:GetPartColorMap()
    return self._PartColorMap
end

function XBigWorldCommanderDIYModel:UpdateFashion(fashionList)
    self._UsePartMap = {}
    self._PartColorMap = {}

    if not XTool.IsTableEmpty(fashionList) then
        for typeId, fashion in pairs(fashionList) do
            self._UsePartMap[typeId] = fashion.PartId
            self._PartColorMap[fashion.PartId] = fashion.ColourId
        end
    end
end

function XBigWorldCommanderDIYModel:GetResIdByPartId(partId, gender)
    local resIds = self:GetDlcPlayerFashionPartResIdById(partId)

    if XTool.IsTableEmpty(resIds) then
        return 0
    end

    gender = self:GetValidGender(gender)

    local resId = resIds[gender]

    return resId or 0
end

function XBigWorldCommanderDIYModel:CheckAllowSelectColor(partId, gender)
    if not XTool.IsNumberValid(partId) then
        return false
    end
    
    local resId = self:GetResIdByPartId(partId, gender)

    if XTool.IsNumberValid(resId) then
        local colorGroupId = self:GetDlcPlayerFashionResColorGroupIdById(resId)

        return XTool.IsNumberValid(colorGroupId)
    end

    return false
end

function XBigWorldCommanderDIYModel:GetValidGender(gender)
    gender = gender or self:GetGender()

    if not XTool.IsNumberValid(gender) then
        gender = XEnumConst.PlayerFashion.Gender.Male
    end

    return gender
end

return XBigWorldCommanderDIYModel
