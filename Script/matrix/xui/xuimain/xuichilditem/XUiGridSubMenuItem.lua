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
    
    self.HandleMap = {
        [XUiConfigs.SubMenuType.System]  = handler(self, self.OnHandleSystem),
        [XUiConfigs.SubMenuType.Operate] = handler(self, self.OnHandleOperate),
    }
end

function XUiGridSubMenuItem:Init(uiRoot)
    self.UiRoot = uiRoot
end

function XUiGridSubMenuItem:OnRefresh(data)
    self.Data = data

    --因两个按钮除了预设图片外没有其他区别，这里默认使用第一个按钮
    self.BtnType1.gameObject:SetActiveEx(true)
    self.BtnType2.gameObject:SetActiveEx(false)
    self.Btn = self.BtnType1
    
    self.Btn:SetNameByGroup(0, data.Title)
    self.Btn:SetNameByGroup(1, data.SubTitle)
    self.Btn.CallBack = function() self:OnBtn() end

    --设置图片
    local isShow
    if data.SubMenuType == XUiConfigs.SubMenuType.System then
        if not string.IsNilOrEmpty(data.BtnIcon) then
            self.Btn:SetSprite(data.BtnIcon)
        end
        isShow = XRedPointManager.CheckConditions(data.RedPointCondition, data.RedPointParam)
    else
        --不是系统那么设置图片就按照传入的图片路径
        local imgPath=XUiConfigs.GetDynamicSubMenuIconPath(data.StyleType)
        if imgPath then
            self.Btn:SetSprite(imgPath)
        end
        isShow = XDataCenter.NoticeManager.CheckSubMenuRedPointIndividual(data.Id)
    end
    self.Btn:ShowReddot(isShow)
end

function XUiGridSubMenuItem:OnBtn()
    local data = self.Data
    local handle = self.HandleMap[data.SubMenuType]
    if handle then handle(data) end
end

function XUiGridSubMenuItem:OnHandleOperate(data)
    if not data.JumpAddr then return end
    local jumType = tonumber(data.JumpType)
    if jumType == JumpType.Web then
        CS.UnityEngine.Application.OpenURL(data.JumpAddr)
    elseif jumType == JumpType.Game then
        XFunctionManager.SkipInterface(tonumber(data.JumpAddr))
    end
    -- 设置已读
    XDataCenter.NoticeManager.ChangeSubMenuReadStatus(data.Id)
    self.Btn:ShowReddot(false)
end

function XUiGridSubMenuItem:OnHandleSystem(data)
    if not data then
        return
    end
    self:RecordSystem(data)
    XFunctionManager.SkipInterface(data.SkipId)
    self.Btn:ShowReddot(XRedPointManager.CheckConditions(data.RedPointCondition, data.RedPointParam))
end

function XUiGridSubMenuItem:RecordSystem(data)
    if not data then
        return
    end
    local dict = {}
    dict["role_id"] = XPlayer.Id
    dict["role_level"] = XPlayer.GetLevel()
    dict["id"] = data.Id
    dict["skip_id"] = data.SkipId
    dict["title"] = data.Title
    
    CS.XRecord.Record(dict, "200016", "UiMainSystemSubMenu")
end

return XUiGridSubMenuItem