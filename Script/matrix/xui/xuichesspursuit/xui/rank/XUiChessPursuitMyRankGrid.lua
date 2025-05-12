local XUiChessPursuitMyRankGrid = XClass(nil, "XUiChessPursuitMyRankGrid")

local MAX_SPECIAL_NUM = 3
local NOT_PERCENT_NUM = 100

function XUiChessPursuitMyRankGrid:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)
    self.TxtPlayerRankHistory.gameObject:SetActiveEx(false)
end

function XUiChessPursuitMyRankGrid:Refresh()
    local isHasMyRank = XDataCenter.ChessPursuitManager.IsHasMyRank()
    if not isHasMyRank then
        self.ImgRankSpecial.gameObject:SetActive(false)
        self.TxtRankNormal.text = CS.XTextManager.GetText("None")
    else
        local myRankNum = XDataCenter.ChessPursuitManager.GetChessPursuitMyRank()
        if myRankNum then
            self.ImgRankSpecial.gameObject:SetActive(myRankNum <= MAX_SPECIAL_NUM)
            if myRankNum <= MAX_SPECIAL_NUM then
                self.TxtRankNormal.text = ""
                local icon = XChessPursuitConfig.GetBabelRankIcon(math.floor(myRankNum))
                self.RootUi:SetUiSprite(self.ImgRankSpecial, icon)
            elseif myRankNum <= NOT_PERCENT_NUM then
                self.TxtRankNormal.text = myRankNum
            end
        else
            myRankNum = XDataCenter.ChessPursuitManager.GetChessPursuitMyRankPercent()
            if myRankNum < 1 then
                myRankNum = 1
            end
            self.TxtRankNormal.text = myRankNum .. "%"
        end
    end    

    self.TxtPlayerName.text = XPlayer.Name
    XUiPlayerHead.InitPortrait(XPlayer.CurrHeadPortraitId, XPlayer.CurrHeadFrameId, self.Head)

    local score = XDataCenter.ChessPursuitManager.GetChessPursuitMyScore()
    self.TxtRankScore.text = score
end

return XUiChessPursuitMyRankGrid