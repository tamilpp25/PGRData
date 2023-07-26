local XUiGridTheatre3Reward = require("XUi/XUiTheatre3/Adventure/Prop/XUiGridTheatre3Reward")

---@class XGridTheatre3RewardChoose : XUiNode
---@field _Control XTheatre3Control
---@field Parent XUiTheatre3RewardChoose
local XGridTheatre3RewardChoose = XClass(XUiNode, "XGridTheatre3RewardChoose")

function XGridTheatre3RewardChoose:OnStart()
    if not self.PanelDifficulty then
        ---@type UnityEngine.Transform
        self.PanelDifficulty = XUiHelper.TryGetComponent(self.Transform, "PanleDifficulty")
    end
    self:AddBtnListener()
end

function XGridTheatre3RewardChoose:Refresh(isProp, data, selectClickFunc)
    self._SelectClickFunc = selectClickFunc
    self._IsProp = isProp
    if self.PanelDifficulty then
        self.PanelDifficulty.gameObject:SetActiveEx(false)
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
function XGridTheatre3RewardChoose:RefreshProp()
    local config = self._Control:GetItemConfigById(self._Id)
    self.TxtTitle.text = config.Name
    self.TxtDescribe.text = config.Description
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
    self._Uid = config.Uid
    if self.PanelDifficulty then
        self.PanelDifficulty.gameObject:SetActiveEx(self._FightReward:GetIsHard())
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
    XUiHelper.RegisterClickEvent(self, self.Transform, self.OnSelfClick)
    XUiHelper.RegisterClickEvent(self, self.BtnYes, self.OnBtnYesClick)
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
            else
                self.Parent:RefreshUi()
            end
        end)
    end
end
--endregion

return XGridTheatre3RewardChoose