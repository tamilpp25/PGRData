---@class XUiGridArchivesCenterFile
local XUiGridArchivesCenterFile = XClass(nil, "XUiGridArchivesCenterFile")

local MAX_CHAT_WIDTH = 180
local MAX_CHAT_WIDTH_ISSUER = 120

---@param rootUi XUiDormArchivesCenter
function XUiGridArchivesCenterFile:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)
    XUiHelper.RegisterClickEvent(self, self.BtnGrid, self.OnBtnGridClick)
end

function XUiGridArchivesCenterFile:Refresh(fileId)
    self.FileId = fileId
    ---@type XDormQuestFile
    self.DormQuestFileViewModel = XDataCenter.DormQuestManager.GetDormQuestFileViewModel(fileId)
    self:RefreshUiData()
end

function XUiGridArchivesCenterFile:RefreshUiData()
    -- 图片
    self.BtnGrid:SetRawImage(self.DormQuestFileViewModel:GetQuestFileDetailCover())
    -- 标题
    self.TxtTitle.text = self.DormQuestFileViewModel:GetQuestFileDetailName()
    -- 超出显示...
    self.TxtMessageLabel.gameObject:SetActiveEx(XUiHelper.CalcTextWidth(self.TxtTitle) > MAX_CHAT_WIDTH)
    -- 发布人
    self.TxtName.text = XDormQuestConfigs.GetQuestAnnouncerNameById(self.DormQuestFileViewModel:GetQuestFileAnnouncer())
    -- 超出显示...
    self.TxtIssuerLabel.gameObject:SetActiveEx(XUiHelper.CalcTextWidth(self.TxtName) > MAX_CHAT_WIDTH_ISSUER)
    -- 文件是否已查阅
    self:RefreshNewFileTab()
end

function XUiGridArchivesCenterFile:RefreshNewFileTab()
    local isReadFile = XDataCenter.DormQuestManager.CheckReadFile(self.FileId)
    self.PanelTag.gameObject:SetActiveEx(not isReadFile)
end

function XUiGridArchivesCenterFile:OnBtnGridClick()
    local isReadFile = XDataCenter.DormQuestManager.CheckReadFile(self.FileId)
    if not isReadFile then
        XDataCenter.DormQuestManager.QuestReadFileRequest(self.FileId, function()
            -- 刷新红点
            self.RootUi:CheckLeftTabBtnRedPoint()
            self:RefreshNewFileTab()
        end)
    end
    XLuaUiManager.Open("UiDormArchivesCenterDetails", self.FileId)
end

return XUiGridArchivesCenterFile