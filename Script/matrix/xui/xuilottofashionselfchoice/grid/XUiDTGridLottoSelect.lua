---@class XUiDTGridLottoSelect
local XUiDTGridLottoSelect = XClass(XUiNode, "XUiDTGridLottoSelect")

function XUiDTGridLottoSelect:OnStart(clickCb)
    self.ClickCb = clickCb
    self.Btn.CallBack = function ()
        if self.Parent.CurSelectGrid then
            self.Parent.CurSelectGrid:SetUnSelect()
        end
        self.Parent.CurSelectGrid = self
        self.Parent.CurSelectGridIndex = self.Index
        self:SetSelect()
        self:OnSelect()
    end
end

function XUiDTGridLottoSelect:Refresh(lottoId, index)
    self.LottoId = lottoId
    self.Index = index

    ---@type XTableLottoFashionSelfChoiceResources
    local lottoResConfig = XLottoConfigs.GetAllConfigs(XLottoConfigs.TableKey.LottoFashionSelfChoiceResources)[lottoId]
    self.Btn:SetSprite(lottoResConfig.EntranceIcon)

    local isAllRewardGet = true
    for k, templateId in pairs(lottoResConfig.SpecialRewardTemplateIds) do
        local count = XGoodsCommonManager.GetGoodsCurrentCount(templateId)
        if count <= 0 then
            isAllRewardGet = false
            break
        end
    end
    self.Btn.TagObj.gameObject:SetActiveEx(isAllRewardGet)
    self.IsAllRewardGet = isAllRewardGet
end

function XUiDTGridLottoSelect:SetSelect()
    self.Select.gameObject:SetActiveEx(true)
end

function XUiDTGridLottoSelect:SetUnSelect()
    self.Select.gameObject:SetActiveEx(false)
end

function XUiDTGridLottoSelect:OnSelect()
    if self.Parent.OnGridSelect then
        self.Parent.OnGridSelect(self.Parent, self.Index, self.LottoId, self)
    end
end

return XUiDTGridLottoSelect