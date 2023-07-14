local MAX_SPECIAL_NUM = 3 --前多少名用特殊数字的图片显示

local ipairs = ipairs

---@class XUiPanelAreaWarMainRank3D 区块排行榜3D的UI
---@field
local XUiPanelAreaWarMainRank3D = XClass(nil, "XUiPanelAreaWarMainRank3D")

function XUiPanelAreaWarMainRank3D:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self.GridList = {}
    self.GridRank.gameObject:SetActiveEx(false)
end

function XUiPanelAreaWarMainRank3D:Refresh(blockId)
    blockId = blockId or self.BlockId
    if not XTool.IsNumberValid(blockId) then
        return
    end

    self.BlockId = blockId
    local block = XDataCenter.AreaWarManager.GetBlock(blockId)

    --我的净化贡献
    self.TxtNumber.text = block:GetSelfPurification()

    local rankList = block:GetRank():GetRankList()
    local isEmpty = XTool.IsTableEmpty(rankList)
    self.ImgEmpty.gameObject:SetActiveEx(isEmpty)
    --前十名排名信息
    for index, rankItem in ipairs(rankList) do
        local grid = self.GridList[index]
        if not grid then
            local go = index == 1 and self.GridRank or CSObjectInstantiate(self.GridRank, self.Content)
            grid = XTool.InitUiObjectByUi({}, go)
            self.GridList[index] = grid
        end

        local rankCount = math.floor(rankItem.Rank)
        if rankCount <= MAX_SPECIAL_NUM then
            local icon = XUiHelper.GetRankIcon(rankCount)
            grid.RImgIconRank:SetRawImage(icon)
            grid.TxtRank.gameObject:SetActiveEx(false)
            grid.RImgIconRank.gameObject:SetActiveEx(true)
        else
            grid.TxtRank.text = math.floor(rankCount)
            grid.RImgIconRank.gameObject:SetActiveEx(false)
            grid.TxtRank.gameObject:SetActiveEx(true)
        end
        grid.TxtNumber.text = rankItem.Score
        grid.TxtName.text = XDataCenter.SocialManager.GetPlayerRemark(rankItem.PlayerId, rankItem.Name)
        XUiPLayerHead.InitPortrait(rankItem.HeadPortraitId, rankItem.HeadFrameId, grid.Head)
        grid.GameObject:SetActiveEx(true)
    end
    for index = #rankList + 1, #self.GridList do
        self.GridList[index].GameObject:SetActiveEx(false)
    end
end

function XUiPanelAreaWarMainRank3D:Show()
    self.GameObject:SetActiveEx(true)
end

function XUiPanelAreaWarMainRank3D:Hide()
    self.GameObject:SetActiveEx(false)
end

return XUiPanelAreaWarMainRank3D
