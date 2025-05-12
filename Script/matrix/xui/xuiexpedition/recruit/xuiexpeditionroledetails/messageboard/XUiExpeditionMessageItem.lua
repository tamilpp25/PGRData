--虚像地平线角色留言板留言控件
local XUiExpeditionMessageItem = XClass(nil, "XUiExpeditionMessageItem")
function XUiExpeditionMessageItem:Ctor()

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

function XUiExpeditionMessageItem:Init(ui, rootUi, eCharId)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    self.ECharId = eCharId
    self.ECharBaseId = XExpeditionConfig.GetBaseIdByECharId(eCharId)
    XTool.InitUiObject(self)
    self.RootUi:RegisterClickEvent(self.BtnLike, function() self:ClickLike() end)
end

function XUiExpeditionMessageItem:RefreshData(commentData)
    XUiPlayerHead.InitPortrait(commentData.Icon, commentData.HeadFrameId, self.Head)
    self.TxtMsg.text = commentData.Content
    self.TxtName.text = commentData.PlayerName
    self.CommentId = commentData.CommentId
    self.DoILike = commentData.DoILike
    if commentData.DoILike then
        self.BtnLike:SetButtonState(CS.UiButtonState.Disable)
    else
        self.BtnLike:SetButtonState(CS.UiButtonState.Normal)
    end
    self.BtnLike:SetName(commentData.LikeCount)
    if commentData.MedalId and commentData.MedalId > 0 then
        local medalConfig = XMedalConfigs.GetMeadalConfigById(commentData.MedalId)
        self.RImgMedal.gameObject:SetActiveEx(true)
        self.RImgMedal:SetRawImage(medalConfig.MedalIcon)
    else
        self.RImgMedal.gameObject:SetActiveEx(false)
    end
    self.TxtLevel.text = commentData.ECharacterLevel
end

function XUiExpeditionMessageItem:ClickLike()
    if self.DoILike then
        XUiManager.TipMsg(CS.XTextManager.GetText("ExpeditionHaveDoLike"))
        return
    end
    XDataCenter.ExpeditionManager.CommentDoLike(self.ECharBaseId, self.CommentId)
end

return XUiExpeditionMessageItem