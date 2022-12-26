-- 主界面二级菜单按钮
local XUiGridSubMenuItem = XClass(nil, "XUiGridSubMenuItem")

local JumpType = {
    Web = 1,
    Game = 2,
}

function XUiGridSubMenuItem:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

function XUiGridSubMenuItem:Init(uiRoot)
    self.UiRoot = uiRoot
end

function XUiGridSubMenuItem:OnRefresh(data)
    self.Data = data
    self.BtnType1.gameObject:SetActiveEx(tonumber(data.StyleType) == 1)
    self.BtnType2.gameObject:SetActiveEx(tonumber(data.StyleType) == 2)
    
    self.Btn = self["BtnType"..data.StyleType] or self.BtnType1
    self.Btn:SetNameByGroup(0, data.Title)
    self.Btn:SetNameByGroup(1, data.SubTitle)
    self.Btn.CallBack = function() self:OnBtn() end
    
    local isShow = XDataCenter.NoticeManager.CheckSubMenuRedPointIndividual(data.Id)
    self.Btn:ShowReddot(isShow)
end

function XUiGridSubMenuItem:OnBtn()
    local data = self.Data
    if not data.JumpAddr then return end
    if tonumber(data.JumpType) == JumpType.Web then
        CS.UnityEngine.Application.OpenURL(data.JumpAddr)
    elseif tonumber(data.JumpType) == JumpType.Game then
        XFunctionManager.SkipInterface(tonumber(data.JumpAddr))
    end
    -- 设置已读
    XDataCenter.NoticeManager.ChangeSubMenuReadStatus(data.Id)
    self.Btn:ShowReddot(false)
end

return XUiGridSubMenuItem