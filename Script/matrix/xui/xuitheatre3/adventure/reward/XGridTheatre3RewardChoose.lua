local XUiGridTheatre3Reward = require("XUi/XUiTheatre3/Adventure/Prop/XUiGridTheatre3Reward")

---@class XGridTheatre3RewardChoose : XUiNode
---@field _Control XTheatre3Control
---@field Parent XUiTheatre3RewardChoose
local XGridTheatre3RewardChoose = XClass(XUiNode, "XGridTheatre3RewardChoose")

function XGridTheatre3RewardChoose:OnStart()
    if not self.ImgRewardTag then
        ---@type UnityEngine.UI.Image
        self.ImgRewardTag = XUiHelper.TryGetComponent(self.Transform, "PanleDifficulty", "Image")
        ---@type UnityEngine.UI.Text
        self.TxtRewardTag = XUiHelper.TryGetComponent(self.Transform, "PanleDifficulty/Text", "Text")
    end
    self:AddBtnListener()
end

function XGridTheatre3RewardChoose:Refresh(isProp, data, selectClickFunc)
    self._SelectClickFunc = selectClickFunc
    self._IsProp = isProp
    if self.ImgRewardTag then
        self.ImgRewardTag.gameObject:SetActiveEx(false)
    end
    if self._IsProp then
        self._Id = data
        self:RefreshProp()
        self:SetSelect(false)
    else
        ---@type XTheatre3NodeReward
        self._FightReward = data
        self._Id = self._FightReward.Uid
        self:RefreshFightReward()
        self:SetSelect(true)
    end
end

--region Ui - Item
function XGridTheatre3RewardChoose:RefreshProp(isAdventureDesc)
    local config = self._Control:GetItemConfigById(self._Id)
    self.TxtTitle.text = config.Name
    -- 处理道具动态数据描述
    local desc = XUiHelper.FormatText(config.Description, isAdventureDesc and self._Control:GetItemEffectGroupDesc(self._Id) or "")
    self.TxtDescribe.text = XUiHelper.ConvertLineBreakSymbol(desc)
    if not self._Grid then
        ---@type XUiGridTheatre3Reward
        self._Grid = XUiGridTheatre3Reward.New(self.PropGrid, self)
    end
    self._Grid:SetData(self._Id, XEnumConst.THEATRE3.EventStepItemType.InnerItem)
    self._Grid:ShowRed(false)
end
--endregion

--region Ui - FightReward
function XGridTheatre3RewardChoose:RefreshFightReward()
    local config = self._Control:GetRewardBoxConfig(self._FightReward.RewardType, self._FightReward.ConfigId)
    self.ImgBox:SetRawImage(config.Icon)
    self.TxtDescribe.text = config.Desc
    self.TxtTitle.text = config.Name
    
    -- 奖励标签
    if not self.ImgRewardTag then
        return
    end
    local tag = self._FightReward:GetTag()
    if self._FightReward:CheckTag(XEnumConst.THEATRE3.NodeRewardTag.None) then
        tag = config.Tag
    end
    if tag == XEnumConst.THEATRE3.NodeRewardTag.None then
        self.ImgRewardTag.gameObject:SetActiveEx(false)
    else
        self.ImgRewardTag.gameObject:SetActiveEx(true)
        local icon = self._Control:GetClientConfig("FightRewardTagIcon", tag)
        local tagTxt = self._Control:GetClientConfig("FightRewardTag", tag)
        if string.IsNilOrEmpty(icon) then
            return
        end
        self.ImgRewardTag:SetSprite(icon)
        self.TxtRewardTag.text = tagTxt
    end
end
--endregion

--region Ui - Select
function XGridTheatre3RewardChoose:SetSelect(isSelect)
    if self.PanelSelect then
        self.PanelSelect.gameObject:SetActiveEx(isSelect)
    end
    self.BtnYes.gameObject:SetActiveEx(isSelect)
end
--endregion

--region Ui - BtnListener
function XGridTheatre3RewardChoose:AddBtnListener()
    self._Control:RegisterClickEvent(self, self.Transform, self.OnSelfClick)
    self._Control:RegisterClickEvent(self, self.BtnYes, self.OnBtnYesClick)
end

function XGridTheatre3RewardChoose:OnSelfClick()
    if self._SelectClickFunc then
        self._SelectClickFunc(self)
    end
end

function XGridTheatre3RewardChoose:OnBtnYesClick()
    if self._IsProp then
        self._Control:RequestAdventureSelectItemReward(self._Id, function()
            self._Control:CheckAndOpenAdventureNextStep(true)
        end)
    else
        local cueId = tonumber(self._Control:GetClientConfig("FightRewardGetSound", self._FightReward:GetType()))
        if XTool.IsNumberValid(cueId) then
            XSoundManager.PlaySoundByType(cueId, XSoundManager.SoundType.Sound)
        end
        self._Control:RequestAdventureRecvFightReward(self._Id, function(isEnd)
            if not self._FightReward:CheckType(XEnumConst.THEATRE3.NodeRewardType.Gold) then
                self._Control:CheckAndOpenAdventureNextStep(true)
            --elseif isEnd then
            --    self.Parent:RefreshUi()
            --    self.Parent:OnBtnBackClick()
            end
        end)
    end
end
--endregion

return XGridTheatre3RewardChoose