local XUiPanelCombatAdditions = XClass(nil, "XUiPanelCombatAdditions")
local XUiGridResAlloBuff = require("XUi/XUiFubenSimulatedCombat/ChildItem/XUiGridResAlloBuff")
local BOUNDARY = 3
function XUiPanelCombatAdditions:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    self.AdditionList = XDataCenter.FubenSimulatedCombatManager.GetCurrentResList(XFubenSimulatedCombatConfig.ResType.Addition)
    XTool.InitUiObject(self)
    self.GridBuff.gameObject:SetActiveEx(false)
    self:InitView()
    self:UpdateView()
end

function XUiPanelCombatAdditions:InitView()
    self.BuffCenterList = {}
    self.BuffLeftList = {}
end

function XUiPanelCombatAdditions:UpdateView()
    self.ResInfo = {}
    self.PanelAdditionCenter.gameObject:SetActiveEx(false)
    self.PanelAdditionLeft.gameObject:SetActiveEx(false)
    self.PanelAdditionNone.gameObject:SetActiveEx(false)
    
    local count = 0
    for _,v in ipairs(self.AdditionList) do
        if v.BuyMethod then
            count = count + 1
            self.ResInfo[count] = XFubenSimulatedCombatConfig.GetAdditionById(v.Id)
        end
    end
    if count == 0 then
        self.PanelAdditionNone.gameObject:SetActiveEx(true)
    elseif count > 0 and count <= BOUNDARY then
        self.PanelAdditionCenter.gameObject:SetActiveEx(true)
        for i = 1, count do
            if not self.BuffCenterList[i] then
                local prefab = CS.UnityEngine.GameObject.Instantiate(self.GridBuff.gameObject)
                prefab.transform:SetParent(self.AdditionCenter, false)
                self.BuffCenterList[i] = XUiGridResAlloBuff.New(prefab, self.RootUi)
            end
            self.BuffCenterList[i]:Show()
            self.BuffCenterList[i]:Refresh(self.ResInfo[i])
        end
        for i = count + 1, #self.BuffCenterList do
            self.BuffCenterList[i]:Hide()
        end
    elseif count > BOUNDARY then
        self.PanelAdditionLeft.gameObject:SetActiveEx(true)
        for i = 1, count do
            if not self.BuffLeftList[i] then
                local prefab = CS.UnityEngine.GameObject.Instantiate(self.GridBuff.gameObject)
                prefab.transform:SetParent(self.AdditionLeft, false)
                self.BuffLeftList[i] = XUiGridResAlloBuff.New(prefab, self.RootUi)
            end
            self.BuffLeftList[i]:Show()
            self.BuffLeftList[i]:Refresh(self.ResInfo[i])
        end
        for i = count + 1, #self.BuffLeftList do
            self.BuffLeftList[i]:Hide()
        end
    end
end

return XUiPanelCombatAdditions