local XUiMoeWarSupportGrid = XClass(nil, "XUiMoeWarSupportGrid")

function XUiMoeWarSupportGrid:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

function XUiMoeWarSupportGrid:Refresh(effectId)
    self.TextName.text = XMoeWarConfig.GetPreparationAssistanceTitle(effectId)
    self.TextInfo.text = XMoeWarConfig.GetPreparationAssistanceDesc(effectId)

    local itemId = XMoeWarConfig.GetPreparationAssistanceVoteItemId(effectId)
    local voteItemCount = XMoeWarConfig.GetPreparationAssistanceVoteItemCount(effectId)
    local ownVoteItemCount = XDataCenter.MoeWarManager.GetSupportVoteItemCount(itemId)
    local isFill = ownVoteItemCount >= voteItemCount
    self.TxtCondition01.gameObject:SetActiveEx(not isFill)
    self.TxtCondition02.gameObject:SetActiveEx(isFill)
    if not isFill then
        local itemName = XDataCenter.ItemManager.GetItemName(itemId)
        local desc = CS.XTextManager.GetText("MoeWarSupportVoteItemCount", itemName, ownVoteItemCount, voteItemCount)
        desc = string.gsub(desc, "\\n", "\n")
        self.TxtCondition01.text = desc
    end

    if self.ImageDark then
        self.ImageDark.gameObject:SetActiveEx(not isFill)
    end
end

return XUiMoeWarSupportGrid