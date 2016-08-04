## 1. Interpolation----------------------

## linear interpolation
LI <- function(x,y,x_inter=x){
    betas <- diff(y)/diff(x)
    intercepts <- y[-1]-betas*x[-1]
    sapply(x_inter,function(i){
        idx <- Position(function(x){i>=x},x,right = TRUE)
        intercepts[idx]+betas[idx]*i
    })
    
}
## cubic spline
CS <- function(){}
## (monotonic) cubic (hermit) spline
MCHS <- function(x,y,x_inter=NULL,mono=FALSE,returnfunction=FALSE){
    ## return interpolation function if returnfunction=TRUE
    n <- length(x)-1                    #number of splines
    if(is.null(x_inter)){
        x_inter <- seq(from = first(x),to = last(x),length.out = 1000)
    }
    if(mono){
        ## reference: wiki
        ## 1
        deltak <- diff(y)/diff(x)
        ## 2
        k <- na.omit(filter(deltak,c(0.5,0.5)))
        k[(deltak[-1]*deltak[-n])<0] <- 0
        k <- c(deltak[1],k,deltak[n])
        ## 4
        ALPHA <- k[-(n+1)]/deltak
        BETA <- k[-1]/deltak
        k[c(ALPHA<=0|BETA<=0,FALSE)] <- 0
        ## 5
        unsatisfy <- ALPHA^2+BETA^2>9
        if(any(unsatisfy)){
            tao <- 3/sqrt(ALPHA[unsatisfy]^2+BETA[unsatisfy]^2)
            k[c(unsatisfy,FALSE)] <- tao*ALPHA[unsatisfy]*deltak[unsatisfy]
            k[c(FALSE,unsatisfy)] <- tao*BETA[unsatisfy]*deltak[unsatisfy]
        }
        ## 3
        k[c(deltak==0,FALSE)|c(FALSE,deltak==0)] <- 0
    }
    else{
        a <- 6/(diff(x)^2)
        b <- 2/diff(x)
        band <- matrix(c(b[-n],na.omit(filter(x=b,filter = c(2,2),sides = 2)),b[-1]),ncol = 3)
        A <- matrix(0,nrow = n+1,ncol = n-1)
        idx <- 1:3
        for(i in 1:(n-1)){
            A[idx] <- band[i,,drop=TRUE]
            idx <- idx+n+2
        }
        A <- t(A)
        
        A <- rbind(c(1,1/2,rep(0,n-1)),
                   A,
                   c(rep(0,n-1),1/2,1))
        B <- c(a[1]*(y[2]-y[1])/2/b[1],
               a[-n]*diff(y[-(n+1)])+a[-1]*diff(y[-1]),
               a[n]*(y[n+1]-y[n])/2/b[n])
        k <- solve(A)%*%B
    }
    interpolation <- function(xp,xa,yp,ya,ka,kp,x){
        P1 <- 3*((xa-x)/(xa-xp))^2 - 2*((xa-x)/(xa-xp))^3
        P2 <- 3*((x-xp)/(xa-xp))^2 - 2*((x-xp)/(xa-xp))^3
        P3 <- (xa-x)^2/(xa-xp) - (xa-x)^3/(xa-xp)^2
        P4 <- (x-xp)^3/(xa-xp)^2 - (x-xp)^2/(xa-xp)
        yp*P1+ya*P2+kp*P3+ka*P4
    }
    ## 'substitude' will substitude variables with their evaluation expressions as well, so here use 'expression' instead.
    expr <- expression(sapply(x_inter,function(i){
        idx <- Position(function(x){i>=x},x,right = TRUE)
        interpolation(xp=x[idx],xa=x[idx+1],
                      yp=y[idx],ya=y[idx+1],
                      kp=k[idx],ka=k[idx+1],
                      x=i)
    }))
    if(!returnfunction){
        return(eval(expr))
    }else{
        ## return interpolation function
        return(eval(parse(text=c(
                  "function(x_inter){",
                  "x=",deparse(x),
                  "y=",deparse(y),
                  "interpolation=",deparse(interpolation),
                  as.character(expr),
                  "}"))))
    }
}


yieldcurve <- c(0.0,1.9676,0.08,2.1025,0.17,2.1471,0.25,2.1923,0.5,2.1957,0.75,2.2681,1.0,2.3039,3.0,2.5313,5.0,2.6586,7.0,2.8204,10.0,2.8268,15.0,3.3289,20.0,3.3432,30.0,3.4778,40.0,3.5731,50.0,3.6481)
x <-yieldcurve[seq(from = 1,to = 31,by = 2)]
y <- yieldcurve[seq(from = 2,to = 32,by = 2)]
x_inter <- seq(0,50,length.out = 1000)

plot(x,y,xlab = "Term(years)",ylab = "Yield(%)",main = "Treasury Bond Yield Curve")
lines(x_inter,LI(x,y,x_inter),lty=3)
lines(x_inter,MCHS(x,y,x_inter),col = "steelblue")
lines(x_inter,MCHS(x,y,x_inter,mono = TRUE),col = "darkorange")

legend(x=35,y=2.5,legend = c("origin","linear","cubic","monotonic"),pch = c(1,NA,NA,NA),lty = c(NA,3,1,1),col = c("black","black","steelblue","darkorange"),bty = "n") #bty: legend box line type, "o" for wrap and "n" for no wrap.

y[11] <- 2.7

## 2. Risk Measures----------------------
rate <- seq(0,2,length.out = 1000)
price <- 100/(1+rate)^5
plot(rate,price,main = "Price-Rate Curve",type = "l")

Yield <- function(cashflows,terms,currentprice){
    obj <- function(r){
        (sum((1+r)^(-terms)*cashflows)-currentprice)^2
    }
    ## minimum .1 basis point
    round(optim(par=0.02,fn = obj,method = "L-BFGS-B",lower = 0,upper = 1)$par,5)
}

Duration <- function(cashflows,terms,currentprice,yield=NULL,modified=TRUE){
    if(is.null(yield)){
        yield <- Yield(cashflows,terms,currentprice)
    }
    if(modified){
        ## modified duration is the first deritive of price to yield multiply by -1/price
        ## modified = macaulay / (1+yield)
        return(sum((1+yield)^(-terms)*cashflows/currentprice*terms)/(1+yield))
    }else{
        ## macaulay duration is just the weighted sum of all cashflow terms.
        ## weights equal the proportion of cashflows' current value to current price.
        return(sum((1+yield)^(-terms)*cashflows/currentprice*terms))
    }
}

DV01 <- function(cashflows,terms,currentprice,yield=NULL,duration=NULL){
    if(is.null(duration)){
        duration <- Duration(cashflows,terms,currentprice,yield)
    }
    ## DV01=-1/10000*dp/dy=1/1000*duration*p
    ## 10000 scale to dollar change per basis point
    duration*currentprice/10000
}

Convexity <- function(){}

cashflows <- c(rep(7,5),107)
terms <- 0.3+0:5
currentprice <- 98.9
Yield(cashflows,terms,currentprice)
Duration(cashflows,terms,currentprice)
DV01(cashflows,terms,currentprice)

## real yieldcurve interpolation
load("data/YieldCurve_EXcorporate")

x <- as.numeric(colnames(yc))
y <- as.numeric(yc[1,])
MCHS(x,y,mono=TRUE)
plot(x,y,xlab = "Term(years)",ylab = "Yield(%)",main = "Coporate Bond Yields")
lines(seq(from = first(x),to = last(x),length.out = 1000),MCHS(x,y,mono = TRUE),col = "darkorange")



## 3. P&L decomposition-----------------
plot(x,y,xlab = "Term(years)",ylab = "Yield(%)",main = "Yield Curve Roll Down")
lines(x_inter,MCHS(x,y,x_inter,mono = TRUE),col = "darkorange")
points(c(27,22),MCHS(x,y,c(27,22),mono = TRUE),pch=20)
segments(c(22,27),c(0,0),c(22,27),MCHS(x,y,c(22,27)),lty=3)
points(x=24.5,y=MCHS(x,y,28),pch="←",cex=2)
text(c(27,22),MCHS(x,y,c(27,22))-0.03,c("27","22"))


plot(x,y,type = "l")

## 4. Bond pricing----------------------

## Black-Scholes formula
## S, K, T, r and sigma denote security price, strike price, term(years), money market annulized continuous rate and annulized volatility respectively
BS <- function(S,K,T,r,sigma=NULL){
    if(is.null(sigma)){
        if(length(S)==1){stop("'S' must contain more than two entries when 'sigma' is NULL!")}
        sigma <- sd(diff(log(S)))
    }
    S <- last(S)
    d1 <- (log(S/K)+(r+sigma^2/2)*T)/sigma/sqrt(T)
    d2 <- d1-sigma*sqrt(T)
    S*pnorm(d1)-K*exp(-r*T)*pnorm(d2)
}

S <- rnorm(50)+100
K <- last(S)
T <- 1
r <- 0.02
BS(S,K,T,r)

## Black's Model
## current price = sum(c(intermediate cashflows, forward price)*c(corresponding discount factors))
## S: bond full price
## cashflows: c(intermediate cashflows, strike price)
## terms: c(terms of intermediate cashflows, term of the option)
## rates: continuous spot rates corresponding to terms
## r: money market rate corresponding to the term of the option
## sigma <- sd(diff(log(clean price)))
BM <- function(S,cashflows,terms,rates,sigma){
    L <- length(cashflows)
    F <- (S-sum(exp(-terms[-L]*rates[-L])*cashflows[-L]))/exp(-rates[L]*terms[L]) #forward price
    
    d1 <- (log(F/cashflows[L])+sigma^2*terms[L]/2)/sigma/sqrt(terms[L])
    d2 <- d1-sigma*sqrt(terms[L])
    c(call=(F*pnorm(d1)-cashflows[L]*pnorm(d2))*exp(-rates[L]*terms[L]),
      put=(cashflows[L]*pnorm(-d2)-F*pnorm(-d1))*exp(-rates[L]*terms[L]))
}

BM(S=960,cashflows = c(50,50,1000),terms = c(0.25,0.75,0.8333),rates = c(0.09,0.095,0.1),sigma = 0.09)

## Black's model applied in callable/putable bond
## S: current full price
## sigma <- sd(diff(log(clean price)))
BM_cp <- function(S,cashflows,terms,rates,sigma,optiontype="call",lower=50,upper=150){

    L <- length(cashflows)
    
    obj <- function(X){
        F <- (X-sum(exp(-terms[-L]*rates[-L])*cashflows[-L]))/exp(-rates[L]*terms[L]) #forward price
        d1 <- (log(F/cashflows[L])+sigma^2*terms[L]/2)/sigma/sqrt(terms[L])
        d2 <- d1-sigma*sqrt(terms[L])
        if(optiontype=="call"){
            abs(S-X-(F*pnorm(d1)-cashflows[L]*pnorm(d2))*exp(-rates[L]*terms[L]))
        }else if(optiontype=="put"){
            abs(S-X+(cashflows[L]*pnorm(-d2)-F*pnorm(-d1))*exp(-rates[L]*terms[L]))
        }else{
            0
        }
    }
    ## minimum .1 basis point
    round(optim(par=S,fn = obj,method = "L-BFGS-B",lower = lower,upper = upper)$par,3)

}

BM_cp(S=96,cashflows = c(5,5,100),terms = c(0.25,0.75,0.8333),rates = c(0.09,0.095,0.1),sigma = 0.04,optiontype = "call")
BM_cp(S=96,cashflows = c(5,5,100),terms = c(0.25,0.75,0.8333),rates = c(0.09,0.095,0.1),sigma = 0.04,optiontype = "put")
