-- 文件详情
---@class XUiDormArchivesCenterDetails : XLuaUi
local XUiDormArchivesCenterDetails = XLuaUiManager.Register(XLuaUi, "UiDormArchivesCenterDetails")

function XUiDormArchivesCenterDetails:OnAwake()
    self:RegisterUiEvents()
    self.TxtTitle.gameObject:SetActiveEx(false)
    self.TxtContent.gameObject:SetActiveEx(false)
end

function XUiDormArchivesCenterDetails:OnStart(fileId)
    self.FileId = fileId
    ---@type XDormQuestFile
    self.DormQuestFileViewModel = XDataCenter.DormQuestManager.GetDormQuestFileViewModel(fileId)
    self:InitUiData()

    self.Timer = XScheduleManager.ScheduleOnce(function()
        local dict = {}
        dict["button"] = XGlobalVar.BtnDorm.BtnUiDormBtnFileDetails
        dict["file_id"] = self.FileId
        CS.XRecord.Record(dict, "200010", "Dorm")
    end, XScheduleManager.SECOND * 1)
end

function XUiDormArchivesCenterDetails:OnEnable()

end

function XUiDormArchivesCenterDetails:OnDisable()

end

function XUiDormArchivesCenterDetails:InitUiData()
    -- 图片
    self.RImgFile:SetRawImage(self.DormQuestFileViewModel:GetQuestFileDetailCover())
    -- 标题
    self.TxtReport.text = self.DormQuestFileViewModel:GetQuestFileDetailTitle()
    -- 发布势力
    local announcerName = XDormQuestConfigs.GetQuestAnnouncerNameById(self.DormQuestFileViewModel:GetQuestFileAnnouncer())
    self.TxtAnnouncerName.text = announcerName
    self.TxtAnnouncerName.gameObject:SetActiveEx(not string.IsNilOrEmpty(announcerName))
    -- 编辑人
    local editorName = self.DormQuestFileViewModel:GetQuestFileDetailEditor()
    self.TxtEditorName.text = editorName
    self.TxtEditorName.gameObject:SetActiveEx(not string.IsNilOrEmpty(editorName))
    -- 审批人
    local approverName = self.DormQuestFileViewModel:GetQuestFileDetailApprover()
    self.TxtApproverName.text = approverName
    self.TxtApproverName.gameObject:SetActiveEx(not string.IsNilOrEmpty(approverName))
    -- 正文
    self:InitFileMessage()
end

function XUiDormArchivesCenterDetails:InitFileMessage()
    -- 显示
    local contentDes = self.DormQuestFileViewModel:GetQuestFileDetailSubContent()
    local titleDes = self.DormQuestFileViewModel:GetQuestFileDetailSubTitle()
    for index, content in pairs(contentDes) do
        local title = titleDes[index]
        if title then
            self:SetTextInfo(self.TxtTitle.gameObject, title)
        end
        self:SetTextInfo(self.TxtContent.gameObject, content)
    end
end

function XUiDormArchivesCenterDetails:SetTextInfo(prefab, info)
    -- 这部分逻辑，后续版本如果可以最好使用XUiNode，通过UiObject注册并访问
    local txtGo = XUiHelper.Instantiate(prefab, self.PanelContent)
    txtGo:SetActiveEx(true)
    local goTxt = txtGo:GetComponent("Text")

    if not goTxt then
        goTxt = txtGo:GetComponent("XUiComponent.XUiRichTextCustomRender")
    end
    
    -- 全角空格转为半角空格
    info = XUiHelper.ReplaceUnicodeSpace(info)
    goTxt.text = XUiHelper.ConvertLineBreakSymbol(info)
end

function XUiDormArchivesCenterDetails:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.OnBtnCloseClick)
end

function XUiDormArchivesCenterDetails:OnBtnCloseClick()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
    self:Close()
end

return XUiDormArchivesCenterDetails