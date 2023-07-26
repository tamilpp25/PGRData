--===============
--宿舍名称控件
--===============
local XUiGuildDormMainTopName = XClass(nil, "XUiGuildDormMainTopName")
--=============
--panel : 控件transform
--mainData : 主页面Data
--=============
function XUiGuildDormMainTopName:Ctor(panel, mainData)
    self.Data = mainData
    XTool.InitUiObjectByUi(self, panel)
    self:InitButtons()
    self:InitEventListeners()
    self:RefreshName()
end

function XUiGuildDormMainTopName:InitButtons()
    XUiHelper.RegisterClickEvent(self, self.BtnClick, function() self:OnClickBtnClick() end)
    self.BtnLeft.CallBack = function() self:OnClickBtnLeft() end
    self.BtnRight.CallBack = function() self:OnClickBtnRight() end
end

function XUiGuildDormMainTopName:InitEventListeners()
    XEventManager.AddEventListener(XEventId.EVENT_GUILD_NAME_CHANGED, self.RefreshName, self)
end

function XUiGuildDormMainTopName:RemoveEventListeners()
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILD_NAME_CHANGED, self.RefreshName, self)
end

function XUiGuildDormMainTopName:OnClickBtnClick()
    if not self:HasAuthority() then
        return
    end
    XLuaUiManager.Open("UiGuildDormSceneChoice")
end

function XUiGuildDormMainTopName:OnClickBtnLeft()
    
end

function XUiGuildDormMainTopName:OnClickBtnRight()
    
end

function XUiGuildDormMainTopName:OnEnable()
    self:RefreshName()
end
--============
--房间名字变更
--============
function XUiGuildDormMainTopName:RefreshName()
    self.Transform:Find("ImgSwitch").gameObject:SetActiveEx(self:HasAuthority())
    local themeId = XDataCenter.GuildDormManager.GetThemeId()
    local themeCfg = XGuildDormConfig.GetThemeCfgById(themeId)
    self.TxtRoomName.text = themeCfg.Name
end

function XUiGuildDormMainTopName:SetShow()
    self.GameObject:SetActiveEx(true)
end

function XUiGuildDormMainTopName:SetHide()
    self.GameObject:SetActiveEx(false)
end

function XUiGuildDormMainTopName:Dispose()
    self:RemoveEventListeners()
end

function XUiGuildDormMainTopName:HasAuthority()
    return XDataCenter.GuildManager.IsGuildLeader() or XDataCenter.GuildManager.IsGuildCoLeader()
end

return XUiGuildDormMainTopName