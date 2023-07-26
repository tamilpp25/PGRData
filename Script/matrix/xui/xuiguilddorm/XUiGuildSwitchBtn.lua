--=============
--新旧公会切换按钮控件
--=============
local XUiGuildSwitchBtn = XClass(nil, "XUiGuildSwitchBtn")

local ARROW_TYPE = {
    UP = 1, --按钮列表收起时箭头表示
    DOWN = 2, --按钮列表打开时箭头表示
}

local LIST_STATUS = {
    SHOW = 1, --按钮列表显示
    HIDE = 2, --按钮列表隐藏
}

function XUiGuildSwitchBtn:Ctor(rootUi, btn, isNew)
    self.IsNew = isNew
    self.RootUi = rootUi
    XTool.InitUiObjectByUi(self, btn)
    self:InitButton()
end

function XUiGuildSwitchBtn:InitButton()
    self:SetListStatus(LIST_STATUS.HIDE)
    self.BtnClick.CallBack = function() self:OnClickBtnClick() end
    self.BtnNewGuild.CallBack = function() self:OnClickBtnNewGuild() end
    self.BtnOldGuild.CallBack = function() self:OnClickBtnOldGuild() end
end

function XUiGuildSwitchBtn:SetListStatus(status)
    self.CurrentListStatus = status
    if status == LIST_STATUS.SHOW then
        self:SetArrow(ARROW_TYPE.DOWN)
        self.BtnList.gameObject:SetActiveEx(true)
    else
        self:SetArrow(ARROW_TYPE.UP)
        self.BtnList.gameObject:SetActiveEx(false)
    end
end

function XUiGuildSwitchBtn:SetArrow(arrowType)
    self.ImgArrowDown.gameObject:SetActiveEx(arrowType == ARROW_TYPE.DOWN)
    self.ImgArrowUp.gameObject:SetActiveEx(arrowType == ARROW_TYPE.UP)
end

function XUiGuildSwitchBtn:OnClickBtnClick()
    local dict = {}
    dict["button"] = XGlobalVar.BtnGuildDormMain.BtnSwitchGuildDorm
    dict["role_level"] = XPlayer.GetLevel()
    CS.XRecord.Record(dict, "200006", "GuildDorm")
    
    if self.CurrentListStatus == LIST_STATUS.SHOW then
        self:SetListStatus(LIST_STATUS.HIDE)
    else
        self:SetListStatus(LIST_STATUS.SHOW)
    end
end

function XUiGuildSwitchBtn:OnClickBtnNewGuild()
    self:SetListStatus(LIST_STATUS.HIDE)
    if self.IsNew then
        XUiManager.TipText("AlreadyInNewGuild")
        return
    end
    XDataCenter.GuildDormManager.EnterGuildDorm(nil, nil, nil, function()
            XLuaUiManager.Remove("UiGuildMain")
        end)
end

function XUiGuildSwitchBtn:OnClickBtnOldGuild()
    self:SetListStatus(LIST_STATUS.HIDE)
    if not self.IsNew then
        XUiManager.TipText("AlreadyInOldGuild")
        return
    end
    XDataCenter.GuildDormManager.RequestExitRoom(function()
            XDataCenter.GuildManager.EnterGuild(function()
                    XLuaUiManager.Remove("UiGuildDormMain")
                    -- XDataCenter.GuildDormManager.Dispose()
                end)
        end)
end

return XUiGuildSwitchBtn