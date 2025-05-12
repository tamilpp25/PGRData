---@class XUiGridBuff: XUiNode
---@field private _Control XGuildWarControl
local XUiGridBuff = XClass(XUiNode, "XUiGridBuff")

function XUiGridBuff:OnStart()
    self:SetButtonCallBack()
end

function XUiGridBuff:OnBackPool()
    self.BuffId = nil
    self.BuffEntity = nil
    self._IsDragonRageBuff = nil
end

function XUiGridBuff:SetButtonCallBack()
    self.BtnBuff.CallBack = function()
        self:OnBtnBuffClick()
    end
end

function XUiGridBuff:UpdateGrid(buffEntity)
    self.BuffEntity = buffEntity
    self.BuffId = nil
    if buffEntity then
        self.RImgIcon:SetRawImage(self.BuffEntity:GetBuffIcon())
        self.TxtLv.text = buffEntity:GetBuffName()
    end
end

---@param buffId @关联StageFightEventDetails.tab
function XUiGridBuff:UpdateGridByBuffId(buffId)
    self.BuffId = buffId
    self.BuffEntity = nil
    if XTool.IsNumberValid(self.BuffId) then
        ---@type XTableStageFightEventDetails
        local cfg = XMVCA.XFuben:GetStageFightEventDetailsByStageFightEventId(self.BuffId)

        if cfg then
            self.RImgIcon:SetRawImage(cfg.Icon)
            self.TxtLv.text = cfg.Name
        end
    end
end

function XUiGridBuff:SetIsDragonRageBuff()
    self._IsDragonRageBuff = true
end

function XUiGridBuff:OnBtnBuffClick()
    if self.BuffEntity then
        XLuaUiManager.Open("UiCommonBuffDetail", self.BuffEntity:GetBuffName(), self.BuffEntity:GetBuffIcon(), self.BuffEntity:GetBuffDesc())
    end

    if XTool.IsNumberValid(self.BuffId) then
        ---@type XTableStageFightEventDetails
        local cfg = XMVCA.XFuben:GetStageFightEventDetailsByStageFightEventId(self.BuffId)
        if cfg then
            XLuaUiManager.Open("UiCommonBuffDetail", cfg.Name, cfg.Icon, self:GetCustomDesc(cfg.Description))
        end
    end
end

function XUiGridBuff:GetCustomDesc(buffDesc)
    if self._IsDragonRageBuff then
        -- 获取周目配置
        local format = self._Control.DragonRageControl:GetGameThroughBuffDescFormat()

        if not string.IsNilOrEmpty(format) then
            return XUiHelper.FormatText(format, self._Control.DragonRageControl:GetDragonRageLevel(), buffDesc)
        end
    end
    
    return buffDesc
end

return XUiGridBuff