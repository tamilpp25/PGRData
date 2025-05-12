local XUiGridBossInshotScore = XClass(XUiNode, "XUiGridBossInshotScore")

function XUiGridBossInshotScore:Refresh(info)
	self:RefreshScoreInfo(info)
end

function XUiGridBossInshotScore:RefreshScoreInfo(scoreInfo)
	local textTitle = self.TxtTitle
	local txtScoreNum = self.TxtScoreNum
	textTitle.text = scoreInfo.Value and string.gsub(scoreInfo.Desc, "{0}", XUiHelper.GetLargeIntNumText(scoreInfo.Value)) or scoreInfo.Desc
	if scoreInfo.Type == XEnumConst.BOSSINSHOT.SCORE_TYPE.Add then
		local score = scoreInfo.Score * scoreInfo.Value / 10
		local txt = "+" .. tostring(math.ceil(score))
		txtScoreNum:TextToSprite(txt, 0)

	elseif scoreInfo.Type == XEnumConst.BOSSINSHOT.SCORE_TYPE.MULTIPLY then
		local score = math.floor(scoreInfo.Score * scoreInfo.Value / 100) -- 小数点后最多保留2位小数
		local txt = "+"  .. tostring(score) .. "%"
		txtScoreNum:TextToSprite(txt, 0)
	else
		txtScoreNum.gameObject:SetActiveEx(false)
	end
end

return XUiGridBossInshotScore
