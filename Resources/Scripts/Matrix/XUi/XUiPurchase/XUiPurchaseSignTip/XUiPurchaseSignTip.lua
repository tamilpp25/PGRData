-- 签到礼包奖励预览脚本，使用签到UI界面，一个脚本对应一个签到prefab
-- 每个签到轮次有一个XUiPurchaseSignTipRound脚本实例

local XUiPurchaseSignTip = XClass(nil, "XUiPurchaseSignTip")

local XUiPurchaseSignTipRound = require("XUi/XUiPurchase/XUiPurchaseSignTip/XUiPurchaseSignTipRound")
local MAX_COUNT = 10

function XUiPurchaseSignTip:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi

    self.PanelRounds = {}
    self.PanelSignPrefabs = {}

    XTool.InitUiObject(self)
    self:InitComponent()
end

function XUiPurchaseSignTip:InitComponent()
    -- 获取并隐藏各个轮次界面
    for i = 1, MAX_COUNT do
        local panelRound = XUiHelper.TryGetComponent(self.Transform, "PanelRound" .. i, nil)
        if not panelRound then
            break
        end
        panelRound.gameObject:SetActiveEx(false)
        table.insert(self.PanelRounds, panelRound)
    end
end

function XUiPurchaseSignTip:Refresh(purchaseData, buyCb)
    self.PurchaseData = purchaseData
    self.BuyCb = buyCb
    local signInInfos = XSignInConfigs.GetSignInInfos(purchaseData.SignInId)

    -- 根据配置信息实例对应的轮次脚本
    for i = 1, #signInInfos do
        local panelRound = self.PanelRounds[i]
        if not panelRound then
            XLog.Error(string.format("XUiPurchaseSignTip:Refresh函数错误，SignInId:%s 的UI界面PanelRound不足，轮次为：%s ", tostring(purchaseData.SignInId), tostring(i)))
            break
        end
        local signPrefab = self.PanelSignPrefabs[i]
        if not signPrefab then
            signPrefab = XUiPurchaseSignTipRound.New(panelRound, self, self.RootUi)
        end
        self.PanelSignPrefabs[i] = signPrefab
        signPrefab:Refresh(purchaseData, i, self.BuyCb)
    end

    -- 默认显示第一个轮次
    self:RefreshPanel(1)
end

function XUiPurchaseSignTip:RegisterTimerFun(id, fun)
    self.RootUi.Parent:RegisterTimerFun(id, fun)
end

function XUiPurchaseSignTip:RemoveTimerFun(id)
    self.RootUi.Parent:RemoveTimerFun(id)
end

---
--- 显示并刷新第'round'轮次的界面
function XUiPurchaseSignTip:RefreshPanel(round)
    for k,v in pairs(self.PanelSignPrefabs) do
        v:SetSignActive(k == round, round)
    end
end

function XUiPurchaseSignTip:OnClose()
    for _, round in pairs(self.PanelSignPrefabs) do
        round:OnClose()
    end

    self.GameObject:SetActiveEx(false)
end

return XUiPurchaseSignTip