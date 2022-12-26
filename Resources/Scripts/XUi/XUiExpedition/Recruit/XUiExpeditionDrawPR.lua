-- 虚像地平线招募公示页面概率项
local XUiExpeditionDrawPR = XClass(nil, "XUiExpeditionDrawPR")
local XTitle = require("XUi/XUiExpedition/Recruit/XUiExpeditionPublicityTitle")
function XUiExpeditionDrawPR:Ctor(ui)
    XTool.InitUiObjectByUi(self, ui)
    self.TxtDesc.gameObject:SetActiveEx(false)
end
--================
--刷新数据
--================
function XUiExpeditionDrawPR:RefreshData(drawPRCfg)
    self.DrawPRCfg = drawPRCfg
    self:SetTitle()
    self:AddPR()
    self:AddDrawPRTimes()
end
--================
--显示左侧等级标题
--================
function XUiExpeditionDrawPR:SetTitle()
    local prefab = CS.UnityEngine.Object.Instantiate(self.TxtDesc.gameObject)
    prefab.transform:SetParent(self.Content, false)
    prefab.gameObject:SetActiveEx(true)
    local title = XTitle.New(prefab.gameObject)
    title:SetTitle(CS.XTextManager.GetText("ExpeditionDrawPRTitle", self.DrawPRCfg.Level))
end
--================
--显示概率分布
--================
function XUiExpeditionDrawPR:AddPR()
    local totalWeight = 0
    for i = 1, #self.DrawPRCfg.RankPR do
        totalWeight = totalWeight + self.DrawPRCfg.RankPR[i]
    end
    for i = 1, #self.DrawPRCfg.RankPR do
        local prefab = CS.UnityEngine.Object.Instantiate(self.TxtDesc.gameObject)
        prefab.transform:SetParent(self.Content, false)
        prefab.gameObject:SetActiveEx(true)
        local title = XTitle.New(prefab.gameObject)
        if self.DrawPRCfg.RankPR[i] and self.DrawPRCfg.RankPR[i] > 0 then
            title:SetTitle(CS.XTextManager.GetText("ExpeditionDrawPRPercent", math.floor(self.DrawPRCfg.RankPR[i] / totalWeight * 100)))
        else
            title:SetTitle("-")
        end
    end
end
--================
--显示刷新次数
--================
function XUiExpeditionDrawPR:AddDrawPRTimes()
    local prefab = CS.UnityEngine.Object.Instantiate(self.TxtDesc.gameObject)
    prefab.transform:SetParent(self.Content, false)
    prefab.gameObject:SetActiveEx(true)
    local title = XTitle.New(prefab.gameObject)
    title:SetTitle(self.DrawPRCfg.NeedRefreshTime)
end
return XUiExpeditionDrawPR