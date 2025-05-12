local XUiGridTheatre4Prop = require("XUi/XUiTheatre4/Common/XUiGridTheatre4Prop")
---@class XUiGridTheatre4RewardCard : XUiNode
---@field private _Control XTheatre4Control
---@field TxtDescribe XUiComponent.XUiRichTextCustomRender
local XUiGridTheatre4RewardCard = XClass(XUiNode, "XUiGridTheatre4RewardCard")

function XUiGridTheatre4RewardCard:OnStart(selectCb, yesCb)
    XUiHelper.RegisterClickEvent(self, self.BtnClick, self.OnBtnClickClick)
    self._Control:RegisterClickEvent(self, self.BtnYes, self.OnBtnYesClick)
    self.ImgBox.gameObject:SetActiveEx(false)
    self.ImgSelect.gameObject:SetActiveEx(false)
    self.PanelDifficulty.gameObject:SetActiveEx(false)
    self.BtnYes.gameObject:SetActiveEx(false)
    self.SelectCallback = selectCb
    self.YesCallback = yesCb
end

-- 获取下标索引
function XUiGridTheatre4RewardCard:GetIndex()
    return self.Index
end

---@param rewardData { Id:number, Type:number, Count:number, Index:number }
function XUiGridTheatre4RewardCard:Refresh(rewardData)
    if not rewardData then
        return
    end
    self.Id = rewardData.Id
    self.Type = rewardData.Type
    self.Count = rewardData.Count or 0
    self.Index = rewardData.Index or 0
    self:RefreshGridProp()
    self:RefreshRewardInfo()
end

function XUiGridTheatre4RewardCard:RefreshGridProp()
    if not self.PanelGridProp then
        ---@type XUiGridTheatre4Prop
        self.PanelGridProp = XUiGridTheatre4Prop.New(self.GridProp, self)
    end
    self.PanelGridProp:Open()
    self.PanelGridProp:Refresh({ Id = self.Id, Type = self.Type, Count = self.Count })
end

function XUiGridTheatre4RewardCard:RefreshRewardInfo()
    -- 名称
    self.TxtTitle.text = self._Control.AssetSubControl:GetAssetName(self.Type, self.Id)
    -- 描述
    self.TxtDescribe.requestImage = function(key, img)
        if key == "Img1" then
            local descIcon = self._Control:GetItemDescIcon(self.Id)
            if descIcon then
                img:SetSprite(descIcon)
            end
        end
    end
    self.TxtDescribe.text = self._Control.AssetSubControl:GetAssetDesc(self.Type, self.Id)
end

-- 设置选择状态
function XUiGridTheatre4RewardCard:SetSelect(isSelect)
    if self.ImgSelect then
        self.ImgSelect.gameObject:SetActiveEx(isSelect)
    end
end

-- 设置确认按钮显示
function XUiGridTheatre4RewardCard:SetBtnYes(isShow)
    if self.BtnYes then
        self.BtnYes.gameObject:SetActiveEx(isShow)
    end
end

function XUiGridTheatre4RewardCard:OnBtnClickClick()
    if self.SelectCallback then
        self.SelectCallback(self)
    end
end

function XUiGridTheatre4RewardCard:OnBtnYesClick()
    if self.YesCallback then
        self.YesCallback(self.Index)
    end
end

function XUiGridTheatre4RewardCard:SetAlpha(alpha)
    self:_InitCanvasGroup()
    if not XTool.UObjIsNil(self._CanvasGroup) then
        self._CanvasGroup.alpha = alpha
    end
end

function XUiGridTheatre4RewardCard:_InitCanvasGroup()
    if XTool.UObjIsNil(self._CanvasGroup) then
        self._CanvasGroup = self.Transform:GetComponent(typeof(CS.UnityEngine.CanvasGroup))
    end
end

function XUiGridTheatre4RewardCard:PlayRewardAnimation()
    self:PlayAnimation("GridRewardCardEnable", function()
        self:SetAlpha(1)
    end)
end

return XUiGridTheatre4RewardCard
