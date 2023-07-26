local CsXTextManager = CS.XTextManager

local XUiPanelHeadGrid = XClass(nil, "XUiSuperTowerTedianUP")

function XUiPanelHeadGrid:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

function XUiPanelHeadGrid:SetData(name, icon)
    self.TxtName.text = name
    self.RImgIcon:SetRawImage(icon)
end

--######################## XUiSuperTowerTedianUP ########################
local XUiSuperTowerTedianUP = XLuaUiManager.Register(XLuaUi, "UiSuperTowerTedianUP")

function XUiSuperTowerTedianUP:OnAwake()
    self.InDultConfig = nil
    self:RegisterUiEvents()
end

function XUiSuperTowerTedianUP:OnStart()
    local roleManager = XDataCenter.SuperTowerManager.GetRoleManager()
    self.InDultConfig = roleManager:GetCurrentInDultConfig()
    if not self.InDultConfig then return end
    roleManager:SetInDultHistoryId(self.InDultConfig.Id)
    -- 特典列表
    self:RefreshCharacterGrids()
    -- 特典描述
    self.TxtBuffTip.text = self.InDultConfig.Desc
    -- 自动关闭
    self:RefreshTimeTip()
    local endTime = XFunctionManager.GetEndTimeByTimeId(self.InDultConfig.TimeId)
    self:SetAutoCloseInfo(endTime, function(isClose)
            if isClose then
                self:Close()
            else
                self:RefreshTimeTip()
            end
        end)
end

function XUiSuperTowerTedianUP:RefreshTimeTip()
    self.TxtTimeTip.text = CS.XTextManager.GetText("CommonRemainTime", self:GetTimeStr())
end

function XUiSuperTowerTedianUP:RefreshCharacterGrids()
    self.PanelHeadGrid.gameObject:SetActiveEx(false)
    local go
    local grid
    for _, id in ipairs(self.InDultConfig.CharacterId) do
        go = CS.UnityEngine.Object.Instantiate(self.PanelHeadGrid, self.PanelHead)
        go.gameObject:SetActiveEx(true)
        grid = XUiPanelHeadGrid.New(go)
        grid:SetData(XEntityHelper.GetCharacterTradeName(id),
            XEntityHelper.GetCharacterSmallIcon(id))
    end
end

function XUiSuperTowerTedianUP:GetTimeStr()
    local endTime = XFunctionManager.GetEndTimeByTimeId(self.InDultConfig.TimeId)
    local nowTime = XTime.GetServerNowTimestamp()
    return XUiHelper.GetTime(endTime - nowTime, XUiHelper.TimeFormatType.ACTIVITY)
end

function XUiSuperTowerTedianUP:RegisterUiEvents()
    self.BtnClose.CallBack = function() self:Close() end
end

return XUiSuperTowerTedianUP
