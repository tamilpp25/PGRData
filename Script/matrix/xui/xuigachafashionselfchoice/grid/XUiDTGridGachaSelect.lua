---@class XUiDTGridGachaSelect
local XUiDTGridGachaSelect = XClass(XUiNode, "XUiDTGridGachaSelect")

function XUiDTGridGachaSelect:OnStart(clickCb)
    self.ClickCb = clickCb
    self.Btn.CallBack = function ()
       self:OnSelect() 
    end
end

function XUiDTGridGachaSelect:Refresh(gachaId, index)
    self.GachaId = gachaId
    self.Index = index

    ---@type XTableGachaFashionSelfChoiceResources
    local gachaConfig = XGachaConfigs.GetAllConfigs(XGachaConfigs.TableKey.GachaFashionSelfChoiceResources)[gachaId]
    self.Btn:SetSprite(gachaConfig.EntranceIcon)

    local isAllRewardGet = true
    for k, templateId in pairs(gachaConfig.SpecialRewardTemplateIds) do
        local count = XGoodsCommonManager.GetGoodsCurrentCount(templateId)
        if count <= 0 then
            isAllRewardGet = false
            break
        end
    end
    self.Btn.TagObj.gameObject:SetActiveEx(isAllRewardGet)
    self.IsAllRewardGet = isAllRewardGet
end

function XUiDTGridGachaSelect:SetSelect()
    self.Select.gameObject:SetActiveEx(true)
end

function XUiDTGridGachaSelect:SetUnSelect()
    self.Select.gameObject:SetActiveEx(false)
end

function XUiDTGridGachaSelect:OnSelect()
    if self.ClickCb then
        self.ClickCb(self.Index, self.GachaId, self)
    end
end

return XUiDTGridGachaSelect