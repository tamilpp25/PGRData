--=============
--场景预览模式切换按钮控件
--=============
local XUiSwitchBtn = XClass(nil, "XUiSwitchBtn")

local ARROW_TYPE = {
    UP = 1, --按钮列表收起时箭头表示
    DOWN = 2, --按钮列表打开时箭头表示
}

local LIST_STATUS = {
    SHOW = 1, --按钮列表显示
    HIDE = 2, --按钮列表隐藏
}

function XUiSwitchBtn:Ctor(ui, isFirst, sceneId, cb)
    self.Ui = ui
    self.IsFirst = isFirst
    self.SceneId = sceneId
    self.Cb = cb
    XTool.InitUiObjectByUi(self, ui)
    self:InitButton()
    self:InitTxt()
end

function XUiSwitchBtn:InitButton()
    self:SetListStatus(LIST_STATUS.HIDE)
    self.BtnClick.CallBack = function() self:OnClickBtnClick() end
    -- 模式选择按钮事件绑定
    self.BtnSelect1.CallBack = function() self:OnClickBtnFirst() end
    self.BtnSelect2.CallBack = function() self:OnClickBtnSecond() end
end

function XUiSwitchBtn:InitTxt()
    self.SwitchDescs = XPhotographConfigs.GetBackgroundSwitchDescById(self.SceneId)
    -- 只有一个模式则不显示模式选择
    if #self.SwitchDescs == 1 then
        self.Ui.gameObject:SetActiveEx(false)
        return
    end

    for i, name in ipairs(self.SwitchDescs) do
        self["TxtSelect" .. i].text = name or "";
    end

    self:RefreshSelect(self.IsFirst)
end

function XUiSwitchBtn:SetListStatus(status)
    self.CurrentListStatus = status
    if status == LIST_STATUS.SHOW then
        self:SetArrow(ARROW_TYPE.DOWN)
        self.BtnList.gameObject:SetActiveEx(true)
    else
        self:SetArrow(ARROW_TYPE.UP)
        self.BtnList.gameObject:SetActiveEx(false)
    end
end

function XUiSwitchBtn:SetArrow(arrowType)
    self.ImgArrowDown.gameObject:SetActiveEx(arrowType == ARROW_TYPE.DOWN)
    self.ImgArrowUp.gameObject:SetActiveEx(arrowType == ARROW_TYPE.UP)
end

-- 刷新选择文本
function  XUiSwitchBtn:RefreshSelect(ifFirst)
    self.TxtTitle.text = self.SwitchDescs[ifFirst and 1 or 2]
end

function XUiSwitchBtn:OnClickBtnClick()
    if self.CurrentListStatus == LIST_STATUS.SHOW then
        self:SetListStatus(LIST_STATUS.HIDE)
    else
        self:SetListStatus(LIST_STATUS.SHOW)
    end
    if self.Cb then self.Cb() end
end

function XUiSwitchBtn:OnClickBtnFirst()
    self:SetListStatus(LIST_STATUS.HIDE)
    if self.TxtTitle.text == self.SwitchDescs[1] then return end

    XDataCenter.PhotographManager.UpdatePreviewState(true)
    self:RefreshSelect(true)

    if self.Cb then self.Cb() end
end

function XUiSwitchBtn:OnClickBtnSecond()
    self:SetListStatus(LIST_STATUS.HIDE)
    if self.TxtTitle.text == self.SwitchDescs[2] then return end

    XDataCenter.PhotographManager.UpdatePreviewState(false)
    self:RefreshSelect(false)

    if self.Cb then self.Cb() end
end

return XUiSwitchBtn