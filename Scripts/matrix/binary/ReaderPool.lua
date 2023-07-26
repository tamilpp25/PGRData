ReaderPool = ReaderPool or {}

local Reader = require("Binary/Reader")

local pool = {}

function ReaderPool.GetReader()
    if #pool <= 0 then
        return Reader.New()
    else
        return table.remove(pool)
    end
end

function ReaderPool.ReleaseReader(reader)
    reader:Close()
    table.insert(pool, reader)
end

function ReaderPool.Clear()
    pool = {}
end