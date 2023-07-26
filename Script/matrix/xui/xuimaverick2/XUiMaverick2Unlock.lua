-- 异构阵线2.0解锁提示界面
local XUiMaverick2Unlock = XLuaUiManager.Register(XLuaUi, "UiMaverick2Unlock")

function XUiMaverick2Unlock:OnAwake()
    self:SetButtonCallBack()
    self:InitTimes()
end

function XUiMaverick2Unlock:OnStart(data)
    self:Refresh(data)
end

function XUiMaverick2Unlock:OnEnable()
    self.Super.OnEnable(self)
end

function XUiMaverick2Unlock:SetButtonCallBack()
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.Close)
end

function XUiMaverick2Unlock:Refresh(data)
    self.TxtTitle.text = data.Title
    self.TxtName.text = data.Name
    self.TxtDes.text = data.Desc
    self.RImgIcon:SetRawImage(data.Icon)
    self.RImgIcon.color = data.IsSkill and CS.UnityEngine.Color.black or CS.UnityEngine.Color.white
end

function XUiMaverick2Unlock:InitTimes()
    self:SetAutoCloseInfo(XDataCenter.Maverick2Manager.GetActivityEndTime(), function(isClose)
        if isClose then
            XLuaUiManager.RunMain()
            XUiManager.TipMsg(XUiHelper.GetText("ActivityAlreadyOver"))
        end
    end)
end