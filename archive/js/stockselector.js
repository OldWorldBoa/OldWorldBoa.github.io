$(document).ready(function() {
  $('#keyboard').jkeyboard({
    input: $('#stockSymbol')
  });
  
  let stockSymbol = getStockSymbol();

  if (!stockSymbol)  {
    // Show input for
    $('#stockSelector').show();
  }
  else
  {
    $('#backToSelector-Container').show();
    showStockGraph(stockSymbol);
  }

  $('#stockSymbolSave').on('click tap', function() {
    setStockSymbol($('#stockSymbol').val());
    $('#stockSelector').hide();
    $('#keyboard').hide();
    $('#backToSelector-Container').show();
    showStockGraph($('#stockSymbol').val());
  });

  $('#backToSelector-Container').on('click tap', function() {
    clearStockSymbol();
    $('#stockSelector').show();
    $('#backToSelector-Container').hide();
    $('#widget').html('');
  });
  
  $('#stockSymbol').on('click tap', function() {
    $('#keyboard').show();
  });
});

var stockSymbolKey = "STOCK_SYMBOL";

function getStockSymbol() {
  return window.localStorage.getItem(stockSymbolKey)
}

function setStockSymbol(newStockSymbol) {
  return window.localStorage.setItem(stockSymbolKey, newStockSymbol)
}

function clearStockSymbol() {
  return window.localStorage.removeItem(stockSymbolKey)
}

function showStockGraph(stockSymbol) {
  setStockSymbol(stockSymbol);

  let dynamicGraph = ' \
  <!-- TradingView Widget BEGIN --> \
  <div class="tradingview-widget-container"> \
    <div class="tradingview-widget-container__widget"></div> \
    <div class="tradingview-widget-copyright"><a href="https://www.tradingview.com/symbols/'+ stockSymbol +'/" rel="noopener" target="_blank"><span class="blue-text">'+ stockSymbol +' Rates</span></a> by TradingView</div> \
    <script type="text/javascript" src="https://s3.tradingview.com/external-embedding/embed-widget-mini-symbol-overview.js" async> \
    { \
    "symbol": "'+ stockSymbol +'", \
    "width": 350, \
    "height": 220, \
    "locale": "en", \
    "dateRange": "12m", \
    "colorTheme": "light", \
    "trendLineColor": "#37a6ef", \
    "underLineColor": "#E3F2FD", \
    "isTransparent": false, \
    "autosize": false, \
    "largeChartUrl": "" \
  } \
    <\/script> \
  </div> \
  <!-- TradingView Widget END -->';

  $('#widget').html(dynamicGraph);
}