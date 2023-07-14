--######################## XUiGridBuff ########################
local XUiGridBuff = XClass(nil, "XUiGridBuff")

function XUiGridBuff:Ctor(ui)
    XUiHelper.InitUiClass(self, ui)
end

function XUiGridBuff:SetData(fightEventId)
    local buffData = XFubenConfigs.GetStageFightEventDetailsByStageFightEventId(fightEventId)
    if buffData == nil then return end
    self.RImgIcon:SetRawImage(buffData.Icon)
    self.TxtName.text = buffData.Name
    self.TxtDesc.text = buffData.Description
end

--######################## XUiGuildWarStageTips ########################
local XUiGuildWarStageTips = XLuaUiManager.Register(XLuaUi, "UiGuildWarStageTips")

function XUiGuildWarStageTips:OnAwake()
    self:RegisterUiEvents()
end

function XUiGuildWarStageTips:OnStart(node)
    self.TxtTitle.text = node:GetHelpTitle()
    self.TxtDetail.text = XUiHelper.ConvertLineBreakSymbol(node:GetHelpDetail())
    local fightEventIds = node:GetFightEventIds()
    if fightEventIds == nil then return end
    XUiHelper.RefreshCustomizedList(self.PanelContent, self.GridBuff, #fightEventIds, function(index, child)
        local buffGrid = XUiGridBuff.New(child)
        buffGrid:SetData(fightEventIds[index])
    end)

end

--######################## 私有方法 ########################

function XUiGuildWarStageTips:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.Close)
end

return XUiGuildWarStageTips