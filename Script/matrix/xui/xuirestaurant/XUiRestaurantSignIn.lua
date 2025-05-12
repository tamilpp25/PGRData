local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
---@class XUiRestaurantSignIn : XLuaUi
---@field _Control XRestaurantControl
local XUiRestaurantSignIn = XLuaUiManager.Register(XLuaUi, "UiRestaurantSignIn")

function XUiRestaurantSignIn:OnAwake()
    self.RewardPanelList = {}

    self:AddBtnListener()
end

function XUiRestaurantSignIn:OnStart()
end

function XUiRestaurantSignIn:OnEnable()
    self:Refresh()
end

-- Ui刷新相关
--------------------------------------------------------------------------------

function XUiRestaurantSignIn:Refresh()
    local business = self._Control:GetBusiness()
    local icon = business:GetSignNpcImgUrl()
    local desc = business:GetSignDescription()
    local replyBtnDesc = business:GetSignReply()
    local rewardId =  business:GetSignRewardId()
    self.Txt.text = business:GetSignActivityName()
    self.HtxtMailContent.text = desc
    if not string.IsNilOrEmpty(icon) then
        self.RImgNpc:SetRawImage(icon)
    end
    -- 奖励刷新
    local rewards = XRewardManager.GetRewardList(rewardId)
    for i = 1, #self.RewardPanelList do
        self.RewardPanelList[i]:Refresh()
    end
    self.BtnClose:SetNameByGroup(0, replyBtnDesc)
    if not rewards then
        return
    end
    for i = 1, #rewards do
        local panel = self.RewardPanelList[i]
        local reward = rewards[i]
        if not panel then
            if #self.RewardPanelList == 0 then
                panel = XUiGridCommon.New(self, self.GridItem)
            else
                local ui = XUiHelper.Instantiate(self.GridItem, self.PanelItemContent)
                panel = XUiGridCommon.New(self, ui)
            end
            table.insert(self.RewardPanelList, panel)
        end
        panel:Refresh(reward)
    end
end

--------------------------------------------------------------------------------

-- 按钮相关
--------------------------------------------------------------------------------

function XUiRestaurantSignIn:AddBtnListener()
    self.BtnClose.CallBack = function ()
        self:OnBtnCloseClick()
    end
    self.BtnCloseBg.CallBack = function ()
        self:OnBtnCloseClick()
    end
end

function XUiRestaurantSignIn:OnBtnCloseClick()
    self:Close()
    -- 发送领取请求
    if XTool.IsNumberValid(self._Control:GetBusiness():GetSignRewardId()) then
        self._Control:RequestRestaurantSign()
    end
end

--------------------------------------------------------------------------------