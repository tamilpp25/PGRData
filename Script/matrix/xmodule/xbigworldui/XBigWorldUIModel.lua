---@class XBigWorldUIModel : XModel
local XBigWorldUIModel = XClass(XModel, "XBigWorldUIModel")

local TableKey = {
    BigWorldUi = {
        ReadFunc = XConfigUtil.ReadType.String,
        DirPath = XConfigUtil.DirectoryType.Client,
        CacheType = XConfigUtil.CacheType.Normal,
        Identifier = "UiName",
    },
}

function XBigWorldUIModel:OnInit()
    self._ConfigUtil:InitConfigByTableKey("BigWorld/Common/Ui", TableKey)

    -- 是否不重复弹出确认框
    self._IsNotRepeatConfirmPopup = {}
end

function XBigWorldUIModel:ClearPrivate()
end

function XBigWorldUIModel:ResetAll()
    self._IsNotRepeatConfirmPopup = {}
end

---@return XTableBigWorldUi
function XBigWorldUIModel:GetUiTemplate(uiMame)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.BigWorldUi, uiMame, true)
end

function XBigWorldUIModel:IsPauseFight(uiName)
    local t = self:GetUiTemplate(uiName)
    return t and t.IsPauseFight or false
end

function XBigWorldUIModel:IsChangeInput(uiName)
    local t = self:GetUiTemplate(uiName)
    return t and t.IsChangeInput or false
end

function XBigWorldUIModel:IsQueue(uiName)
    local t = self:GetUiTemplate(uiName)
    return t and t.IsQueue or false
end

function XBigWorldUIModel:IsCloseLittleMap(uiName)
    local t = self:GetUiTemplate(uiName)
    return t and t.IsCloseLittleMap or false
end

function XBigWorldUIModel:IsHideFightUi(uiName)
    local t = self:GetUiTemplate(uiName)
    return t and t.IsHideFightUi or false
end

function XBigWorldUIModel:GetHideUiNames(uiName)
    local t = self:GetUiTemplate(uiName)
    return t and t.HideUiNames or nil
end

function XBigWorldUIModel:SetIsNotRepeatConfirmPopup(key, value)
    self._IsNotRepeatConfirmPopup[key] = value
end

function XBigWorldUIModel:IsNotRepeatConfirmPopup(key)
    return self._IsNotRepeatConfirmPopup[key] or false
end

return XBigWorldUIModel
