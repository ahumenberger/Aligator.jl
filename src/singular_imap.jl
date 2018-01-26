
cxxinclude(joinpath("Singular", "maps_ip.h"), isAngled = false)

import Singular.PolyRing
import Singular.spoly

function imap(src::Singular.libSingular.ring, dst::Singular.libSingular.ring, p::Singular.libSingular.poly)
    icxx"""
        ring r = $(src);
        rChangeCurrRing($(dst));

        int *perm=NULL;
        int *par_perm=NULL;
        int par_perm_size=0;
        // map between coefficients?!
        nMapFunc nMap;
        if ((nMap=n_SetMap(r->cf,currRing->cf))==NULL)
        {
            // TODO: is this really necessary?
            // Allow imap/fetch to be make an exception only for:
            if ( (rField_is_Q_a(r) &&  // Q(a..) -> Q(a..) || Q || Zp || Zp(a)
                (rField_is_Q(currRing) || rField_is_Q_a(currRing) ||
                    (rField_is_Zp(currRing) || rField_is_Zp_a(currRing))))
                ||
                (rField_is_Zp_a(r) &&  // Zp(a..) -> Zp(a..) || Zp
                (rField_is_Zp(currRing, r->cf->ch) ||
                    rField_is_Zp_a(currRing, r->cf->ch))) )
            {
                par_perm_size=rPar(r);
            }
            else
            {
                Werror("no map between coefficients");
            }
        }

        perm=(int *)omAlloc0((r->N+1)*sizeof(int));    
        if (par_perm_size!=0)
            par_perm=(int *)omAlloc0(par_perm_size*sizeof(int));

        int r_par=0;
        char ** r_par_names=NULL;
        if (r->cf->extRing!=NULL)
        {
        r_par=r->cf->extRing->N;
        r_par_names=r->cf->extRing->names;
        }
        int c_par=0;
        char ** c_par_names=NULL;
        if (currRing->cf->extRing!=NULL)
        {
        c_par=currRing->cf->extRing->N;
        c_par_names=currRing->cf->extRing->names;
        }
        maFindPerm(r->names,r->N,r_par_names,r_par,
                currRing->names,currRing->N,c_par_names,c_par,
                perm,par_perm,currRing->cf->type);

        // current poly
        sleftv w;
        memset(&w,0,sizeof(sleftv));
        w.rtyp=POLY_CMD;
        w.data=$(p);
        // resulting poly
        leftv res=(leftv)omAllocBin(sleftv_bin);
        res->Init();
        res->rtyp=POLY_CMD;
        // apply map
        if (maApplyFetch(IMAP_CMD,NULL,res,&w,r,perm,par_perm,par_perm_size,nMap))
        {
            Werror("cannot map poly");
        }
        // cleanup
        if (perm!=NULL)
            omFreeSize((ADDRESS)perm,(r->N+1)*sizeof(int));
        if (par_perm!=NULL)
            omFreeSize((ADDRESS)par_perm,par_perm_size*sizeof(int));
        // return
        (poly)res->Data();
    """
end

function imap(p::spoly{T}, dst::PolyRing{T}) where T <: Nemo.RingElem
    src = parent(p)
    if src == dst
        return p
    end
    ptr = imap(src.ptr, dst.ptr, p.ptr)
    dst(ptr)
end

