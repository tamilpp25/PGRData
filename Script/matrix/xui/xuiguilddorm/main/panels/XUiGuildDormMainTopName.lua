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
    local roomData = XDataCenter.GuildDormManager.GetCurrentRoom():GetRoomData()
    self.TxtRoomName.text = roomData:GetName()
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

return XUiGuildDormMainTopName