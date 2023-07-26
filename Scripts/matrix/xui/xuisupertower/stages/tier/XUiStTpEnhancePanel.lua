local Base = require("XUi/XUiSuperTower/Common/XUiSTChildPanel")
--=====================
--爬塔准备增益掉落面板
--=====================
local XUiStTpEnhancePanel = XClass(Base, "XUiStTpEnhancePanel")
--===============
--初始化面板(在构筑函数最后调用)
--===============
function XUiStTpEnhancePanel:InitPanel()
    self.GridEnhance.gameObject:SetActiveEx(false)
    self.BtnDetails.CallBack = function() self:OnClickBtnDetails() end
    self.TxtDetails.text = XUiHelper.GetText("STTierPrepareEnhanceTip")
end

function XUiStTpEnhancePanel:OnShowPanel()
    local isStart = self.RootUi:GetIsStart()
    self.TxtDetails.gameObject:SetActiveEx(isStart)
    self.ObjEnhance.gameObject:SetActiveEx(not isStart)
    if not isStart then
        self:ShowEnhanceList()
    end
end

function XUiStTpEnhancePanel:ShowEnhanceList()
    local list = self.RootUi.Theme:GetTierEnhanceIds()
    if not self.EnhanceList then self.EnhanceList = {} end
    table.sort(list, function(idA, idB)
                local cfgA = XSuperTowerConfigs.GetEnhanceCfgById(idA)
                local cfgB = XSuperTowerConfigs.GetEnhanceCfgById(idB)
                if not cfgA then
                    return true
                end
                if not cfgB then
                    return false
                end
                return cfgA.Priority < cfgB.Priority
            end)
    if list then
        for i = 1, #list do
            if list[i] then
                if not self.EnhanceList[i] then
                    local script = require("XUi/XUiSuperTower/Plugins/XUiSuperTowerEnhanceGrid")
                    local enhanceGo = CS.UnityEngine.Object.Instantiate(self.GridEnhance, self.PanelEnhance)
                    self.EnhanceList[i] = script.New(enhanceGo, function(enhance) self:OnClickEnhance(enhance) end)
                end
                self.EnhanceList[i]:ShowPanel()
                self.EnhanceList[i]:RefreshData(list[i])
            else
                if self.EnhanceList[i] then
                    self.EnhanceList[i]:HidePanel()
                end
            end
        end
    end
end

function XUiStTpEnhancePanel:OnClickEnhance(enhanceGrid)
    XLuaUiManager.Open("UiSuperTowerEnhanceDetails", enhanceGrid.EnhanceId)
end

function XUiStTpEnhancePanel:OnClickBtnDetails()
    XLuaUiManager.Open("UiSuperTowerItemTip", self.RootUi.Theme, XDataCenter.SuperTowerManager.ItemType.Enhance, not self.RootUi.Theme:CheckTierIsPlaying())
end

return XUiStTpEnhancePanel