CryptoReaderPool = CryptoReaderPool or {}

local CryptoReader = require("Binary/CryptoReader")

local cryptoPool = {}

---@return CryptoReader
function CryptoReaderPool.GetReader()
    if #cryptoPool <= 0 then
        return CryptoReader.New()
    else
        return table.remove(cryptoPool)
    end
end

function CryptoReaderPool.ReleaseReader(reader)
    reader:Close()
    table.insert(cryptoPool, reader)
end