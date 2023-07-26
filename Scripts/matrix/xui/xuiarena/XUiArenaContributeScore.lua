---通用接口，处理战区的贡献分
local XUiArenaContributeScore = {}
local TXT_COLOR_RED = "FF3F3FFF"
local defaultColor = nil 

--[[
    --@txtCom:text component
	--@contributeScore:贡献分
	--@point:战区积分
	--@defaultColor: 默认的颜色值
]]
function XUiArenaContributeScore.Refresh(txtCom, contributeScore, point, defaultColor)
    if XTool.UObjIsNil(txtCom) or not contributeScore or not point then 
        XLog.Error("参数不可以有空的")
        return 
    end

    if contributeScore == 0 and point == 0 then
        txtCom.color = XUiHelper.Hexcolor2Color(TXT_COLOR_RED)
    else
        if defaultColor then
            txtCom.color = XUiHelper.Hexcolor2Color(defaultColor)
        end
    end

    txtCom.text = "+" .. contributeScore
end

return XUiArenaContributeScore