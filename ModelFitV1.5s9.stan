//runs, 1 patient, all params. = 1
//MWE 
//  + prior per theta & theta initialisation
//  + looped observation fitting
//  + multiple IDs (same values and time points)
//  + Y0s
//  + all etas

functions{
  real[] ode(     real time,
                  real[] y,
                  real[] theta,
                  real[] x_r,
                  int[] x_i) {
        
        real dydt[3];
        
        dydt[1] = -theta[1] * y[1] * y[3] + theta[2];
        dydt[2] = theta[1] * y[1] * y[3] - theta[3] * y[2];
        dydt[3] = theta[4] * y[2] - theta[5] * y[3];
        
        return dydt;
  }
}

data {
        int<lower = 1> nSubjects;
        int<lower = 1> nObs;
        int<lower = 1> nODEs;
        int<lower = 1> s[nSubjects];
        int<lower = 1> gen_time_N;

        real Y0s[nSubjects];
        real t0;
        real time[nObs];
        real obs[nObs];
        
        real gen_time[gen_time_N]; 
      }


transformed data {
      real x_r[0];
      int x_i[0];
}


parameters {

      real <lower = 0> beta;
      real <lower = 0> lambda;
      real <lower = 0> delta;
      real <lower = 0> rho;
      //real <lower = 0> c;
      real <lower = 0> sigma;
      
      vector[nSubjects] eta_beta;
      vector[nSubjects] eta_lambda;
      vector[nSubjects] eta_delta;
      vector[nSubjects] eta_rho;
      vector[nSubjects] eta_c;
}


transformed parameters {
      real z[nObs, nODEs];
      real theta[5];
      
      real c;
      
      {
      int position;
      position = 1;
      
      c = 1;
      
      for (subject in 1:nSubjects) {
        real yhat[s[subject], 3];
        real Y0[nODEs];
        
        theta[1] = beta * exp(eta_beta[subject]);
        theta[2] = lambda * exp(eta_lambda[subject]);
        theta[3] = delta * exp(eta_delta[subject]);
        theta[4] = rho * exp(eta_rho[subject]);
        //theta[5] = c * exp(eta_c[subject]); //Forces model instability
        theta[5] = c;

      
        Y0[1] = Y0s[subject];
        Y0[2] = 0;
        Y0[3] = 100;
          
        yhat = 
          integrate_ode_rk45(ode, Y0, t0, 
          time[position:position+s[subject]-1], theta, 
          x_r, x_i);
        
        
        z[position:position+s[subject]-1] = yhat;
        position = position + s[subject];

        }
      }
}


model { 
                                              
      beta ~ normal(1, 0.2);
      lambda ~ normal(1, 0.2);
      delta ~ normal(1, 0.2);
      rho ~ normal(1, 0.2);
      //c ~ normal(1, 0.2);
      sigma ~ cauchy(0, 1);
      
      eta_beta ~ normal(0, 0.1);
      eta_lambda ~ normal(0, 0.1);
      eta_delta ~ normal(0, 0.1);
      eta_rho ~ normal(0, 0.1);
      eta_c ~ normal(0, 0.1);
      
      for (n in 1:nObs){
        obs[n] ~ normal(z[n,nODEs], sigma);
      }
}


generated quantities{

}



