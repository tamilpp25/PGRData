--肉鸽2.0活动奖励面板
local XUiBiancaTheatrePanelReward = XClass(nil, "XUiBiancaTheatrePanelReward")
local MAX_REWARD_LEVEL = XBiancaTheatreConfigs.GetMaxRewardLevel()

function XUiBiancaTheatrePanelReward:Ctor(ui, isNotOpenReward)
    self.Gameobject = ui.gameObject
    self.Transform = ui.transform
    self.IsNotOpenReward = isNotOpenReward  --是否不打开奖励界面
    XTool.InitUiObject(self)
    self:Init()
end

function XUiBiancaTheatrePanelReward:Init()
    self.BtnReward = self.Transform:GetComponent("XUiButton")
    self.ImgPercentNormal = XUiHelper.TryGetComponent(self.Transform, "Normal/PanelDegree/ImgPercentNormal", "Image")
    self.ImgPercentPress = XUiHelper.TryGetComponent(self.Transform, "Press/PanelDegree/ImgPercentPress", "Image")

    XUiHelper.RegisterClickEvent(self, self.BtnReward, handler(self, self.OnBtnRewardClick))
end

function XUiBiancaTheatrePanelReward:Refresh()
    --当前奖励等级
    local level = XDataCenter.BiancaTheatreManager.GetCurRewardLevel()
    if self.BtnReward then
        self.BtnReward:SetNameByGroup(1, level)
    end
    --经验进度
    local nextRewardLevel = level + 1
    local curTotalExp = XDataCenter.BiancaTheatreManager.GetCurExpWithLv(level)
    
    local nextExp = MAX_REWARD_LEVEL >= nextRewardLevel and XBiancaTheatreConfigs.GetLevelRewardUnlockScore(nextRewardLevel) or 0
    local percent = XTool.IsNumberValid(nextExp) and curTotalExp / nextExp or 1
    if self.BtnReward then
        self.BtnReward:SetNameByGroup(0, XTool.IsNumberValid(nextExp) and string.format("%d/%d", curTotalExp, nextExp) or XBiancaTheatreConfigs.GetRewardTips(3))
    end
    if self.ImgPercentNormal then
        self.ImgPercentNormal.fillAmount = percent
    end
    if self.ImgPercentPress then
        self.ImgPercentPress.fillAmount = percent
    end
    --检查尚未领取的核心奖励红点
    self:CheckRed()
end

function XUiBiancaTheatrePanelReward:CheckRed()
    if self.BtnReward then
        self.BtnReward:ShowReddot(not self.IsNotOpenReward and XDataCenter.BiancaTheatreManager.ExCheckIsShowRedPoint())
    end
end

--打开奖励界面
function XUiBiancaTheatrePanelReward:OnBtnRewardClick()
    if self.IsNotOpenReward then
        return
    end

    XLuaUiManager.Open("UiBiancaTheatreLvReward", function()
        if XTool.UObjIsNil(self.Gameobject) then
            return
        end
        self:CheckRed()
    end)
end

return XUiBiancaTheatrePanelReward