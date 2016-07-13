## 1.interpolation----------------------

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
MCHS <- function(x,y,x_inter=x,mono=FALSE){
    n <- length(x)-1                    #number of splines
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
    sapply(x_inter,function(i){
        idx <- Position(function(x){i>=x},x,right = TRUE)
        interpolation(xp=x[idx],xa=x[idx+1],
                      yp=y[idx],ya=y[idx+1],
                      kp=k[idx],ka=k[idx+1],
                      x=i)
    })
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

## 2. risk measures----------------------
rate <- seq(0,2,length.out = 1000)
price <- 100/(1+rate)^5
plot(rate,price,main = "Price-Rate Curve",type = "l")
