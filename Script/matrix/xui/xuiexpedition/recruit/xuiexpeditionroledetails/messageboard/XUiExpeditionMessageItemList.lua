local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
--虚像地平线角色留言板留言列表
local XUiExpeditionMessageItemList = XClass(nil, "XUiExpeditionMessageItemList")
local XUiExpeditionMessageItem = require("XUi/XUiExpedition/Recruit/XUiExpeditionRoleDetails/MessageBoard/XUiExpeditionMessageItem")
function XUiExpeditionMessageItemList:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)
    self:ResetCommentsList()
    self:InitDynamicTable()
end

function XUiExpeditionMessageItemList:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.GameObject)
    self.DynamicTable:SetProxy(XUiExpeditionMessageItem)
    self.DynamicTable:SetDelegate(self)
end
--动态列表事件
function XUiExpeditionMessageItemList:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(grid.DynamicGrid.gameObject, self.RootUi, self.ECharaId)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        if self.CommentsList and self.CommentsList[index] then
            grid:RefreshData(self.CommentsList[index])
        end
        if self.NextPage and index == #self.CommentsList then
            self:GetComment()
        end
    end
end

function XUiExpeditionMessageItemList:ResetCommentsList()
    self.PageNo = 1
    self.CommentsList = {}
    self.MyComments = nil
end

function XUiExpeditionMessageItemList:GetComment()
    XDataCenter.ExpeditionManager.GetComment(self.ECharBaseId, self.PageNo)
end
--[[    commentData结构
{
int CommentId;           // 留言id
int PlayerId;            // 玩家id
int Icon;                // 头像
int HeadFrameId;         // 头像框
string PlayerName;       // 玩家名字
int MedalId;             // 勋章id
string Content;          // 留言内容
int ECharacterLevel;     // 留言的对象等级
int LikeCount;           // 点赞数
bool DoILike;            // 我是否点赞
}]]
function XUiExpeditionMessageItemList:OnSendMyMessage(commentId, commentText)
    local MyComments = {
        CommentId = commentId,
        PlayerId = XPlayer.Id,
        Content = commentText,
        DoILike = false,
        ECharacterLevel = XExpeditionConfig.GetCharacterCfgById(self.ECharaId).Rank,
        MedalId = XPlayer.CurrMedalId,
        PlayerName = XPlayer.Name,
        Icon = XPlayer.CurrHeadPortraitId,
        HeadFrameId = XPlayer.CurrHeadFrameId,
        LikeCount = 0,
        }
    local newCommentList = {}
    table.insert(newCommentList, MyComments)
    for i = 1, #self.CommentsList do
        table.insert(newCommentList, self.CommentsList[i])
    end
    self.RootUi.ImgEmpty.gameObject:SetActiveEx(false)
    self.CommentsList = newCommentList
    self.DynamicTable:SetDataSource(self.CommentsList)
    self.DynamicTable:ReloadDataASync(1)
end

function XUiExpeditionMessageItemList:UpdateData(eCharaId)
    self.ECharaId = eCharaId
    self.ECharBaseId = XExpeditionConfig.GetBaseIdByECharId(eCharaId)
    self:GetComment()
end

function XUiExpeditionMessageItemList:OnReceiveComments(commentsList, pageNo)
    self:AddComments(commentsList)
    self.DynamicTable:SetDataSource(self.CommentsList)
    self.DynamicTable:ReloadDataASync(-1)
end

function XUiExpeditionMessageItemList:AddComments(commentsList)
    self.RootUi.ImgEmpty.gameObject:SetActiveEx(not (commentsList and #commentsList > 0))
    if commentsList and #commentsList > 0 then
        for i in pairs(commentsList) do
            table.insert(self.CommentsList, commentsList[i])
        end
        if #self.CommentsList % 20 == 0 and #self.CommentsList < 100 then
            self.PageNo = self.PageNo + 1
            self.NextPage = true
        else
            self.NextPage = false
        end
    end
end

function XUiExpeditionMessageItemList:OnDoLike(commentId)
    for _, v in pairs (self.CommentsList) do
        if v.CommentId == commentId then
            v.DoILike = true
            v.LikeCount = v.LikeCount + 1
        end
    end
    self.DynamicTable:SetDataSource(self.CommentsList)
    self.DynamicTable:ReloadDataASync(-1)
end

function XUiExpeditionMessageItemList:AddListener()
    if self.IsAddedListener then return end
    self.IsAddedListener = true
    XEventManager.AddEventListener(XEventId.EVENT_EXPEDITION_COMMENTS_RECEIVE, self.OnReceiveComments, self)
    XEventManager.AddEventListener(XEventId.EVENT_EXPEDITION_COMMENTS_SEND, self.OnSendMyMessage, self)
    XEventManager.AddEventListener(XEventId.EVENT_EXPEDITION_COMMENTS_DOLIKE, self.OnDoLike, self)
end

function XUiExpeditionMessageItemList:OnEnable()
    self:AddListener()
    self:ResetCommentsList()
end

function XUiExpeditionMessageItemList:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_EXPEDITION_COMMENTS_RECEIVE, self.OnReceiveComments, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_EXPEDITION_COMMENTS_SEND, self.OnSendMyMessage, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_EXPEDITION_COMMENTS_DOLIKE, self.OnDoLike, self)
    self.IsAddedListener = false
end

return XUiExpeditionMessageItemList